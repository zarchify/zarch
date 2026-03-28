--!strict
local Types = require(script.Parent.types)

local StateMachine = {}
StateMachine.__index = StateMachine

--[[
    recursive method which goes into a branch and flags each state it passes as active,
    firing on_entry and branching into parallel or initial children it finds
]]--
local function enter_node<Ctx, EventData>(machine: Types.StateMachine<Ctx, EventData>, node: Types.RuntimeStateNode<Ctx, EventData>, event_data: EventData?, skip_self: boolean?)
    if not skip_self then
        machine.active_nodes[node._id] = true
        if node.on_entry then
            local cleanup = node.on_entry(machine.context, event_data)
            if cleanup then
                machine._cleanups[node._id] = cleanup
            end
        end
    end
    
    if node.parallel and node.states then
        for _, child in node.states do
            enter_node(machine, child, event_data)
        end
    elseif node.initial and node.states then
        local initial_child = node.states[node.initial]
        if initial_child then
            enter_node(machine, initial_child, event_data)
        end
    end
end

-- exits all nodes below the ancestor
local function exit_nodes_below<Ctx, EventData>(machine: Types.StateMachine<Ctx, EventData>, ancestor: Types.RuntimeStateNode<Ctx, EventData>?)
    local descendants: { { node: Types.RuntimeStateNode<Ctx, EventData>, depth: number } } = {}
    for id, _ in machine.active_nodes do
        local node = machine.id_map[id]
        if node then
            local curr: Types.RuntimeStateNode<Ctx, EventData>? = node
            local is_descendant = false
            local depth = 0
            while curr do
                if curr == ancestor then
                    is_descendant = true
                    break
                end
                curr = curr._parent
                depth = depth + 1
            end
            
            if is_descendant and node ~= ancestor then
                table.insert(descendants, { node = node, depth = depth })
            end
        end
    end
    
    table.sort(descendants, function(a: any, b: any) return a.depth > b.depth end)
    
    for _, item in descendants do
        local node = item.node
        
        if node.on_exit then
            node.on_exit(machine.context)
        end
        
        local cleanup = machine._cleanups[node._id]
        if cleanup then
            cleanup()
            machine._cleanups[node._id] = nil
        end
        
        machine.active_nodes[node._id] = nil
    end
end

--[[
    climbs to find the lowest common ancestor (closest shared parent) between the old and new states
    so that send knows when to stop calling on_exits and start calling on_entries
]]--
local function get_lca<Ctx, EventData>(nodeA: Types.RuntimeStateNode<Ctx, EventData>?, nodeB: Types.RuntimeStateNode<Ctx, EventData>?): Types.RuntimeStateNode<Ctx, EventData>?
    if not nodeA or not nodeB then return nil end
    local pathA = {}
    local curr: Types.RuntimeStateNode<Ctx, EventData>? = nodeA
    while curr do
        pathA[curr] = true
        curr = curr._parent
    end
    
    curr = nodeB
    while curr do
        if pathA[curr] then return curr end
        curr = curr._parent
    end
    return nil
end

--[[
    scans active states and filters out the parents returning only the deepest leaf nodes
]]--
local function get_active_leaf_nodes<Ctx, EventData>(machine: Types.StateMachine<Ctx, EventData>): { Types.RuntimeStateNode<Ctx, EventData> }
    local leaves = {}
    for id, _ in machine.active_nodes do
        local node = machine.id_map[id]
        if node then
            local is_leaf = true
            if node.states then
                for child_id, _ in node.states do
                    if machine.active_nodes[child_id] then
                        is_leaf = false
                        break
                    end
                end
            end
            if is_leaf then
                table.insert(leaves, node)
            end
        end
    end
    return leaves
end

--[[
    creates a new state machine.

    @param config: MachineConfig -- the config as defined by the exported type
    @param options: MachineOptions? -- optional options for the state machine

    @return StateMachine: StateMachine -- the new state machine
]]--
function StateMachine.create_machine<Ctx, EventData>(config: Types.MachineConfig<Ctx, EventData>, context: Ctx, options: Types.MachineOptions<Ctx, EventData>?): Types.StateMachine<Ctx, EventData>
    local self: any = setmetatable({
        config = config,
        options = options,
        context = context,
        id_map = {},
        active_nodes = {},
        _cleanups = {},
        _started = false,
    }, StateMachine)
    
    local function parse_node(id: string, node_config: Types.StateNodeConfig<Ctx, EventData>, parent: Types.RuntimeStateNode<Ctx, EventData>?): Types.RuntimeStateNode<Ctx, EventData>
        local runtime_node: any = {
            _id = id,
            _parent = parent,
            on_entry = node_config.on_entry,
            on_exit = node_config.on_exit,
            events = node_config.events,
            initial = node_config.initial,
            parallel = node_config.parallel,
            states = nil
        }
        
        self.id_map[id] = runtime_node
        
        if node_config.states then
            runtime_node.states = {}
            for child_id, child_config in node_config.states do
                runtime_node.states[child_id] = parse_node(child_id, child_config, runtime_node)
            end
        end
        
        return runtime_node
    end

    local root_id = config.id or "root"
    local root_runtime_node: any = {
        _id = root_id,
        _parent = nil,
        initial = config.initial,
        parallel = config.parallel,
    }
    self.id_map[root_id] = root_runtime_node
    
    if config.states then
        root_runtime_node.states = {}
        for child_id, child_config in config.states do
            root_runtime_node.states[child_id] = parse_node(child_id, child_config, root_runtime_node)
        end
    end
    
    self.root = root_runtime_node
    
    return self
end


--[[
    starts the state machine. 

    @return ()
]]--
function StateMachine.start<Ctx, EventData>(self: Types.StateMachine<Ctx, EventData>): ()
    if self._started then return end
    self._started = true
    enter_node(self, self.root, nil)
end

--[[
    sends an event into the state machine. finds a node that can handle the event, exits out of old states,
    fires any inline actions, and enters the new state.

    @param event: string -- the event
]]--
function StateMachine.send<Ctx, EventData>(self: Types.StateMachine<Ctx, EventData>, event: string, event_data: EventData?): ()
    if not self._started then return end
    
    local leaves = get_active_leaf_nodes(self)
    local source_node: Types.RuntimeStateNode<Ctx, EventData>? = nil
    local transition: Types.Transition<Ctx, EventData>? = nil
    
    for _, leaf in leaves do
        local curr: Types.RuntimeStateNode<Ctx, EventData>? = leaf
        while curr do
            if curr.events and curr.events[event] then
                source_node = curr
                transition = curr.events[event]
                break
            end
            curr = curr._parent
        end
        if transition then break end
    end
    
    if not transition or not source_node then return end
    
    local target_id: string?
    local actions_to_run
    
    if type(transition) == "string" then
        target_id = transition
    elseif type(transition) == "table" then
        target_id = transition.target
        actions_to_run = transition.actions
    end
    
    if actions_to_run then
        for _, action in actions_to_run do
            if type(action) == "function" then
                action(self.context, event_data)
            elseif type(action) == "string" and self.options and self.options.actions then
                local action_fn = self.options.actions[action]
                if action_fn then 
                    action_fn(self.context, event_data) 
                end
            end
        end
    end
    
    if target_id then
        local target_node = self.id_map[target_id]
        if target_node then
            local lca = get_lca(source_node, target_node)
            exit_nodes_below(self, lca)
            
            local path_to_target: { Types.RuntimeStateNode<Ctx, EventData> } = {}
            local curr: Types.RuntimeStateNode<Ctx, EventData>? = target_node
            while curr and curr ~= lca do
                table.insert(path_to_target, 1, curr)
                curr = curr._parent
            end
            
            for _, node in path_to_target do
                self.active_nodes[node._id] = true
                if node.on_entry then 
                    local cleanup = node.on_entry(self.context, event_data) 
                    if cleanup then
                        self._cleanups[node._id] = cleanup
                    end
                end
            end
            
            enter_node(self, target_node, event_data, true)
        end
    end
end

--[[
    simple o(1) check if a node is active. better than spamming send in 99999% of cases

    @return boolean -- true if node is active, false if otherwise
]]--
function StateMachine.get_active_state<Ctx, EventData>(self: Types.StateMachine<Ctx, EventData>, node_id: string): boolean
    return self.active_nodes[node_id] or false
end

return StateMachine

--!strict

export type CleanupFn = () -> ()
export type ActionFn<Ctx, EventData> = (context: Ctx, event_data: EventData?) -> CleanupFn?

export type TransitionConfig<Ctx, EventData> = {
    target: string?,
    actions: { string | ActionFn<Ctx, EventData> }?,
    guards: { string | ((context: Ctx, event_data: EventData?) -> boolean) }?
}

export type Transition<Ctx, EventData> = string | TransitionConfig<Ctx, EventData> | { TransitionConfig<Ctx, EventData> }

export type StateNodeConfig<Ctx, EventData> = {
    on_entry: ActionFn<Ctx, EventData>?,
    on_exit: ((context: Ctx) -> ())?,
    events: { [string]: Transition<Ctx, EventData> }?,
    
    initial: string?,
    parallel: boolean?,
    states: { [string]: StateNodeConfig<Ctx, EventData> }?,
}

export type MachineConfig<Ctx, EventData> = {
    id: string?,
    initial: string?,
    parallel: boolean?,
    states: { [string]: StateNodeConfig<Ctx, EventData> }
}

export type MachineOptions<Ctx, EventData> = {
    actions: { [string]: ActionFn<Ctx, EventData> }?,
    guards: { [string]: ((context: Ctx, event_data: EventData?) -> boolean) }?
}

export type RuntimeStateNode<Ctx, EventData> = {
    on_entry: ActionFn<Ctx, EventData>?,
    on_exit: ((context: Ctx) -> ())?,
    events: { [string]: Transition<Ctx, EventData> }?,
    
    initial: string?,
    parallel: boolean?,
    states: { [string]: RuntimeStateNode<Ctx, EventData> }?,
    
    _id: string,
    _parent: RuntimeStateNode<Ctx, EventData>?,
}

export type StateMachine<Ctx, EventData> = {
    config: MachineConfig<Ctx, EventData>,
    options: MachineOptions<Ctx, EventData>?,
    context: Ctx,
    
    root: RuntimeStateNode<Ctx, EventData>,
    id_map: { [string]: RuntimeStateNode<Ctx, EventData> },
    active_nodes: { [string]: boolean },
    _started: boolean,
    _cleanups: { [string]: CleanupFn },
    
    start: (self: StateMachine<Ctx, EventData>) -> (),
    send: (self: StateMachine<Ctx, EventData>, event: string, event_data: EventData?) -> (),
    get_active_state: (self: StateMachine<Ctx, EventData>, node_id: string) -> boolean,
}

return nil

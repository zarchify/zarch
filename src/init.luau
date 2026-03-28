--!strict
local Types = require(script.types)
local Machine = require(script.machine)

export type CleanupFn = Types.CleanupFn
export type ActionFn<Ctx, EventData> = Types.ActionFn<Ctx, EventData>
export type Transition<Ctx, EventData> = Types.Transition<Ctx, EventData>
export type StateNodeConfig<Ctx, EventData> = Types.StateNodeConfig<Ctx, EventData>
export type MachineConfig<Ctx, EventData> = Types.MachineConfig<Ctx, EventData>
export type MachineOptions<Ctx, EventData> = Types.MachineOptions<Ctx, EventData>
export type RuntimeStateNode<Ctx, EventData> = Types.RuntimeStateNode<Ctx, EventData>
export type StateMachine<Ctx, EventData> = Types.StateMachine<Ctx, EventData>

return {
    create_machine = Machine.create_machine,    
}

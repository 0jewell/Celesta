--!strict
local Celesta = script.Parent
local Component = require(Celesta.Component)
local AssertComponentData = Component.AssertComponentData
local AssertComponent = Component.AssertComponent

local Types = require(Celesta.Types)
type Entity = Types.Entity
type World = Types.World

type Component<D> = Types.Component<D>
type ComponentData<D> = Types.ComponentData<D>

local Entity = {}
Entity.__index = Entity

local function NewEntity(world: World): Types.Entity
    
    local nextId = world._nextId
    world._nextId += 1

    return setmetatable({

        _world = world,
        _storage = {},
        _id = nextId

    }, Entity) :: any
end

function Entity.Add(self: Entity, ...: ComponentData<unknown>)
    local modified = {}

    for index, data in { ... } do

        AssertComponentData(data :: any, index)

        local metatable = getmetatable(data :: any)
        local id = metatable._id

        self._storage[id] = data :: ComponentData<unknown>

        table.insert(modified, id)
    end

    self._world:_applyTraits(self, modified)
end

function Entity.Remove(self: Entity, ...: Component<unknown>)
    local modified = {}

    for index, component in { ... } do
        
        AssertComponent(component, index)

        local id = component._id

        local datatype = self._storage[id]
        datatype:Clean()

        self._storage[id] = nil

        table.insert(modified, id)
    end

    self._world:_applyTraits(self, modified)
end

function Entity.Get(
    self: Entity,
    ...: Component<unknown>
): ...ComponentData<unknown> | boolean

    local results = {} :: { ComponentData<unknown> | boolean }

    for index, component in { ... } do
        
        AssertComponent(component, index)

        local id = component._id
        local datatype = self._storage[id]

        if not datatype then
            table.insert(results, false)
        end

        table.insert(results, datatype)
    end

    return unpack(results)
end

function Entity.Clear(self: Entity)
    local modified = {}

    for id, data in self._storage do
        
        AssertComponentData(data :: any, id)
        data:Clean()

        table.insert(modified, id)
    end 

    table.clear(self._storage)

    self._world:_applyTraits(self, modified)
end

function Entity.Destruct(self: Entity)
    self:Clear()

    self._world._storage[self._id] = nil

    table.clear(self)
end

return NewEntity
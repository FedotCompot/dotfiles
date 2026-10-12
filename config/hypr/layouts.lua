-- See https://wiki.hypr.land/Configuring/Layouts/Custom-Layouts/
-- Equal-width columns side by side (vim's :vsplit)
hl.layout.register("vertical", { recalculate = function(ctx)
    local n = #ctx.targets
    for i, target in ipairs(ctx.targets) do target:place(ctx:column(i, n)) end
end })

-- Equal-height rows stacked top to bottom (vim's :split)
hl.layout.register("horizontal", { recalculate = function(ctx)
    local n = #ctx.targets
    for i, target in ipairs(ctx.targets) do target:place(ctx:row(i, n)) end
end })

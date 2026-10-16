-- Helium picture-in-picture (sets no class)
hl.window_rule({
    name              = "float-helium-pip",
    match             = { class = "^$", title = "^Picture in picture$" },
    float             = true,
    pin               = true,
    keep_aspect_ratio = true,
    rounding          = 0,
})

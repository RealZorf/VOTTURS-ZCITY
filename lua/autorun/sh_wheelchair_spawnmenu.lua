if SERVER then
    AddCSLuaFile()
    return
end

list.Set( "GlideCategories", "Z-City", {
    name = "Z-City",
    icon = "glide/icons/car.png"
} )

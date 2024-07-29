export type ObjectScript = {
  type: "ObjectScript",
  runner: (self: ObjectScript, object: Instance, scope: { unknown }) -> (),
}

return nil

hl.curve('myBezier', { type = 'bezier', points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })

hl.animation {
  leaf = 'windows',
  enabled = false,
  speed = 7.0,
  bezier = 'myBezier',
}

hl.animation {
  leaf = 'windowsOut',
  enabled = false,
  speed = 7.0,
  style = 'popin 80%',
}

hl.animation {
  leaf = 'border',
  enabled = false,
  speed = 10.0,
}

hl.animation {
  leaf = 'borderangle',
  enabled = false,
  speed = 8.0,
}

hl.animation {
  leaf = 'fade',
  enabled = false,
  speed = 7.0,
}

hl.animation {
  leaf = 'workspaces',
  enabled = false,
  speed = 6.0,
}

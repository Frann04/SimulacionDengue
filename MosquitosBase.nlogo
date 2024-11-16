breed [mosquitos mosquito]
breed [personas persona]
breed [charcos charco]
breed [huevos huevo]

globals [ultimo-movimiento-charcos tick-de-muerte-lista promedio-ticks-muerte]

mosquitos-own [
  ya-pico?
  tick-de-muerte
  cant-picaduras
]

charcos-own [
  incubando?
  tick-de-incubacion
  huevos-infectados?
]

personas-own [
  duracion-de-enfermedad
  tick-fin-inmunidad
  vacunado?
]


huevos-own [
  edad
  incubando?
  en-charco?
]

to vacunar-poblacion
  let personas-no-vacunadas personas with [not vacunado? and color = green]
  ;; Si la cantidad de personas no vacunadas es mayor o igual a la cantidad a vacunar, vacunar exactamente esa cantidad
  ifelse count personas-no-vacunadas >= cantidad-a-vacunar [
    ask n-of cantidad-a-vacunar personas-no-vacunadas [
      set vacunado? true
      set color violet  ;; Color violeta para personas vacunadas
      set tick-fin-inmunidad ticks + ((((random (duracion-max-inmunidad - duracion-min-inmunidad)) + duracion-min-inmunidad) * 24) / mul_ticks)
    ]
  ] [
    ;; Si hay menos personas no vacunadas que la cantidad deseada, vacunar a todas las disponibles
    ask personas-no-vacunadas [
      set vacunado? true
      set color violet
      set tick-fin-inmunidad ticks + ((((random (duracion-max-inmunidad - duracion-min-inmunidad)) + duracion-min-inmunidad) * 24) / mul_ticks)
    ]
  ]
end

to actualizar-plot
  set-current-plot "Promedio ticks muerte"
  plot promedio-ticks-muerte
end

to setup
  clear-all
  reset-ticks

  set ultimo-movimiento-charcos 0
  set tick-de-muerte-lista []

  import-drawing "Mapa_La_Plata.jpg"

  create-personas Poblacion [
    setxy random-xcor random-ycor
    set shape "person"
    set color green
    set duracion-de-enfermedad 0
    set tick-fin-inmunidad 0
    set vacunado? false  ;; Inicialmente nadie está vacunado
  ]

  repeat cant-personas-infectadas [
    ask one-of personas with [color = green] [
      set color red
    ]
  ]

  create-mosquitos cant-mosquitos [
    setxy random-xcor random-ycor
    set color yellow
    set shape "bicho"
    set ya-pico? false
    set tick-de-muerte ticks + ((((random (vida-max-mosquitos - vida-min-mosquitos)) + vida-min-mosquitos) * 24) / mul_ticks) ;; vivira entre max y min (parametros de entrada)
      ;; Agregar el nuevo valor a la lista
    set tick-de-muerte-lista lput tick-de-muerte tick-de-muerte-lista

    actualizar-plot-tick-de-muerte tick-de-muerte

    set cant-picaduras 0
  ]

  repeat cant-mosquitos-infectados [
    ask one-of mosquitos with [color = yellow] [
      set color orange
    ]
  ]

  create-charcos cant-charcos [
    setxy random-pxcor random-pycor
    set shape "circle"
    set color blue
    set incubando? false
    set huevos-infectados? false
  ]
end

to actualizar-plot-tick-de-muerte [var]
  set-current-plot "Distribucion de vida de mosquitos"
  plot (var * mul_ticks) / 24 ;; muestra el grafico en dias
end

to go
  tick

  mover-charcos-aleatorios
  matar-mosquitos-viejos
  incubar-huevos

  ask mosquitos with [not ya-pico?] [
    rt random 100
    lt random 100
    fd (velocidad-mosquito-ticks * mul_ticks)
  ]

ask mosquitos with [ya-pico?] [
  let charco-mas-cercano min-one-of(charcos)[distance myself]
  face charco-mas-cercano
  if distance charco-mas-cercano <= 1 [
    ;; Depositar huevo en el charco más cercano
    ask charco-mas-cercano [
      hatch-huevos 1 [
        setxy [xcor] of charco-mas-cercano [ycor] of charco-mas-cercano
        set color white
        set edad 0
        set incubando? true
      ]
    ]
    set ya-pico? false
  ]
]

  ;; Modificada la lógica de infección para considerar la vacunación
  ask personas with [color = green or color = violet] [
    if (count (mosquitos-here with [color = orange and not ya-pico?]) > 0) [
      ifelse vacunado? [

        if random 100 < chance-de-infeccion-vacunado [
          set duracion-de-enfermedad ticks + ((((random (duracion-min-enfermedad - duracion-max-enfermedad)) + duracion-min-enfermedad) * 24) / mul_ticks)
          set color red
        ]
      ] [
        ;; Si no está vacunado, probabilidad normal
        if random 100 < chance-de-infeccion-sin-vacunar [
          set duracion-de-enfermedad ticks + ((((random (duracion-min-enfermedad - duracion-max-enfermedad)) + duracion-min-enfermedad) * 24) / mul_ticks)
          set color red
        ]
      ]
    ]
  ]

  ask mosquitos with [not ya-pico?] [
    let personas-en-el-mismo-lugar personas-here

    if any? personas-en-el-mismo-lugar with [color = red] [
      set color orange
    ]

    if count (personas-en-el-mismo-lugar) > 0 [
      set ya-pico? true
      set cant-picaduras (cant-picaduras + 1)
    ]
  ]

  eclosionar-huevos
  curar-gente
  terminar-inmunidad
end

to mover-mosquito
    fd 1
end

to matar-mosquitos-viejos
  ask mosquitos [
    if (tick-de-muerte <= ticks) or cant-picaduras > 4 [
      die
    ]
  ]
end

to eclosionar-huevos
  ask charcos with [color = 75] [
    if (tick-de-incubacion <= ticks) [
      generar-mosquitos huevos-infectados?
      set color blue
      set incubando? false
      set tick-de-incubacion 0
    ]
  ]
end

to generar-mosquitos [infectados?]
  hatch-mosquitos cantidad-de-huevos-por-charco [
    set color yellow
    set shape "bicho"
    set ya-pico? false
    set tick-de-muerte ticks + ((((random (vida-max-mosquitos - vida-min-mosquitos)) + vida-min-mosquitos) * 24) / mul_ticks) ;; vivira entre max y min (parametros de entrada)
    set cant-picaduras 0

    if infectados? and (random 100 < 50) [ set color orange ]
  ]
end

to curar-gente
  ask personas with [color = red] [
    if duracion-de-enfermedad <= ticks [ ;;paso el tiempo de enfermedad (tick actual es mayor que tick de curacion)
      ifelse vacunado? [
        set color violet  ;; Las personas vacunadas vuelven a violet
      ] [
        set color green   ;; Las no vacunadas vuelven a verde
      ]
      set duracion-de-enfermedad 0
    ]
  ]
end

to incubar-huevos
  ask huevos [
    if incubando? [
      set edad edad + 1
      if edad >= 120 [
        ;; Generar hasta 10 mosquitos si el huevo ha estado suficiente tiempo
        hatch-mosquitos 10 [
          set color yellow
          set shape "bicho"
          set ya-pico? false
          set tick-de-muerte ticks + ((((random (vida-max-mosquitos - vida-min-mosquitos)) + vida-min-mosquitos) * 24) / mul_ticks)
          set cant-picaduras 0
        ]
        die
      ]
    ]
  ]
end

to terminar-inmunidad
  ask personas with [color = violet] [
    if (ticks = tick-fin-inmunidad) [  ; Check if N ticks (days) have passed since vaccination
      set color green   ; Unvaccinated persons return to green
      set vacunado? false
    ]
  ]
end

to mover-charcos-aleatorios
  if ticks - ultimo-movimiento-charcos >= 100 [
    set ultimo-movimiento-charcos ticks
    let charcos-a-mover n-of (ceiling (0.05 * count charcos)) charcos ;;se mueve el 5% de los charcos
    ask charcos-a-mover [
      rt random 360
      fd 1
    ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
1167
12
1839
685
-1
-1
13.0
1
10
1
1
1
0
1
1
1
-25
25
-25
25
0
0
1
ticks
30.0

BUTTON
17
16
80
49
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
17
101
80
134
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
16
58
79
91
NIL
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
90
16
262
49
Poblacion
Poblacion
0
200
15.0
1
1
NIL
HORIZONTAL

SLIDER
92
101
264
134
cant-charcos
cant-charcos
0
100
80.0
1
1
NIL
HORIZONTAL

SLIDER
271
17
454
50
cant-mosquitos
cant-mosquitos
1
1000
172.0
1
1
NIL
HORIZONTAL

SLIDER
93
58
263
91
cant-personas-infectadas
cant-personas-infectadas
0
Poblacion
0.0
1
1
NIL
HORIZONTAL

SLIDER
270
58
452
91
cant-mosquitos-infectados
cant-mosquitos-infectados
0
cant-mosquitos
1.0
1
1
NIL
HORIZONTAL

SLIDER
271
104
479
137
chance-de-infeccion-vacunado
chance-de-infeccion-vacunado
0
100
45.0
1
1
NIL
HORIZONTAL

PLOT
17
192
525
437
cantidad de mosquitos
1 tick = mul_ticks horas
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Total" 1.0 0 -13840069 true "" "plot count mosquitos"
"Con dengue" 1.0 0 -2674135 true "" "plot count mosquitos with[color = orange]"
"Sin dengue" 1.0 0 -1184463 true "" "plot count mosquitos with[color = yellow]"

PLOT
549
233
919
437
Personas
ticks (8hs)
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"sanas" 1.0 0 -13840069 true "" "plot count personas with[color = green or color = violet]"
"infectadas" 1.0 0 -2674135 true "" "plot count personas with[color = red]"

SLIDER
18
146
266
179
cantidad-de-huevos-por-charco
cantidad-de-huevos-por-charco
1
50
7.0
1
1
NIL
HORIZONTAL

SLIDER
579
22
751
55
cantidad-a-vacunar
cantidad-a-vacunar
0
100
50.0
1
1
NIL
HORIZONTAL

BUTTON
840
21
915
54
Vacunar
vacunar-poblacion
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
550
62
915
225
Personas vacunadas
ticks (8hs)
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"vacunadas" 1.0 0 -10141563 true "" "plot count personas with[ color = violet]"

SLIDER
275
148
494
181
chance-de-infeccion-sin-vacunar
chance-de-infeccion-sin-vacunar
0
100
80.0
1
1
NIL
HORIZONTAL

SLIDER
291
531
503
564
vida-min-mosquitos
vida-min-mosquitos
0
100
14.0
1
1
Dias
HORIZONTAL

SLIDER
293
580
506
613
vida-max-mosquitos
vida-max-mosquitos
0
100
30.0
1
1
dias
HORIZONTAL

SLIDER
9
448
283
481
mul_ticks
mul_ticks
1
25
1.0
1
1
Mutliplicador ticks x horas
HORIZONTAL

SLIDER
9
487
273
520
duracion-min-enfermedad
duracion-min-enfermedad
7
14
7.0
1
1
en dias
HORIZONTAL

SLIDER
8
530
274
564
duracion-max-enfermedad
duracion-max-enfermedad
7
14
14.0
1
1
NIL
HORIZONTAL

PLOT
833
451
1140
625
Distribucion de vida de mosquitos
NIL
Dias de vida
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"asd" 1.0 0 -7500403 true "" "plot tick_de_muerte_lista"

SLIDER
548
488
810
522
duracion-min-inmunidad
duracion-min-inmunidad
1
450
70.0
1
1
En dias
HORIZONTAL

SLIDER
546
446
811
480
duracion-max-inmunidad
duracion-max-inmunidad
10
450
100.0
1
1
En dias
HORIZONTAL

SLIDER
289
448
539
482
tiempo-min-incubacion
tiempo-min-incubacion
7
10
7.0
1
1
En dias
HORIZONTAL

SLIDER
290
487
537
521
tiempo-max-incubacion
tiempo-max-incubacion
7
10
10.0
1
1
En dias
HORIZONTAL

SLIDER
233
620
570
654
velocidad-mosquito-ticks
velocidad-mosquito-ticks
0.01
2
0.21
0.2
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

bicho
true
0
Polygon -7500403 true true 180 120 210 120 255 120 278 141 273 175 240 180 210 165 180 150 150 150 150 135
Polygon -7500403 true true 150 105 132 169 120 210 126 233 150 256 172 236 180 210 168 167
Circle -7500403 true true 135 90 30
Polygon -7500403 true true 120 121 90 121 45 121 26 139 29 173 60 181 90 166 120 151 150 151 150 136
Polygon -7500403 true true 141 105 150 30 158 105 150 105

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@

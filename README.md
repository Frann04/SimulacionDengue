Simulación de Mosquitos y Vacunación en NetLogo 🦟💉
Este proyecto implementa una simulación en NetLogo que modela la propagación de enfermedades transmitidas por mosquitos y los efectos de la vacunación en una población humana. Está diseñado para estudiar dinámicas epidemiológicas y evaluar estrategias de intervención como la vacunación y el control de vectores.

Características Principales 🚀
Población humana:

Representada por agentes (personas) con estados de salud (saludable, infectado, vacunado).
Personas vacunadas tienen una inmunidad temporal de 5 días.
La vacunación reduce en un 80% la probabilidad de contagio.
Mosquitos como vectores de la enfermedad:

Pueden picar a humanos y transmitir enfermedades si están infectados.
Ciclo de vida limitado: mueren después de un número determinado de días o picaduras.
Charcos como criaderos:

Permiten la eclosión de huevos, generando nuevos mosquitos (algunos infectados).
Parámetros ajustables:

Cantidad de humanos, mosquitos y charcos.
Probabilidades de infección, duración de la enfermedad y tiempo de incubación.
Dinámica del sistema:

Las personas infectadas pueden curarse después de un tiempo.
Los mosquitos infectados pueden propagar la enfermedad si pican a personas no inmunizadas.
Cómo Usar el Modelo 🖥️
Configuración inicial (setup):
Define la cantidad inicial de personas, mosquitos y charcos.
Vacuna a una parte específica de la población.
Simulación (go):
Los agentes interactúan en un entorno simulado donde los mosquitos se mueven, pican y transmiten enfermedades.
Los charcos generan nuevos mosquitos según su estado de incubación.
Objetivos de la Simulación 🎯
Analizar la propagación de enfermedades transmitidas por vectores.
Evaluar el impacto de la vacunación en la reducción de contagios.
Experimentar con distintos parámetros para optimizar las estrategias de control.
Requisitos 🔧
NetLogo 6.0 o superior.
Archivo del modelo .nlogo.

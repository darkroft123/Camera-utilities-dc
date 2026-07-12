# README

- 🇺🇸 [English](#-english)
- 🇪🇸 [Español](#-español)

---

# 🇺🇸 English

# How to Download

You can download the project by pressing the green Code button and then selecting Download ZIP or [clicking here](https://github.com/Martincraft7887/modcharteditor-cne-1.0.1/archive/refs/heads/main.zip)

Once downloaded:

Extract the .zip file  
Place the folder inside mods in your Codename Engine installation.

The path should look like this:

Codename Engine/mods/modcharts

If you want to include it inside your own mod, simply move the contents of the modcharts folder into your mod folder.

# Additional Information

If you do not have basic knowledge of configuration in Codename Engine, you can modify the file:

data/config/modpack.ini

From there you can:

Change the window name  
Modify the application icon  
Change the Discord RPC icon


# How to Use
[Here](https://youtu.be/Or5PCoG4HkQ) you can see a tutorial vid 
Open Codename Engine  
Press TAB to select the mod (if it is not active)  
Go to:  
Settings  
Miscellaneous Options  
Enable Developer Mode

![This](https://github.com/Martincraft7887/Things/blob/44ab769bf22ee8c1e4cf9b59cac79423b0cd5bab/TutorialImages/This.png)

Return to the main menu  
Press 7

![There](https://github.com/Martincraft7887/Things/blob/44ab769bf22ee8c1e4cf9b59cac79423b0cd5bab/TutorialImages/There.png)

Select Modchart Editor (it is located at the bottom)  
Choose a song from your mod and start editing


# Creating Modcharts by Difficulty

If you want to use a different Modchart for each difficulty:

Go to the song folder:

YourMod/songs/YourSong/

There you will find:

modchart.xml

![Modchart](https://github.com/Martincraft7887/Things/blob/d28a721f6cac7e4c254f0c7ba41ea0541d63eee3/TutorialImages/modchart.png)

Rename it according to the difficulty:

modchart-hard.xml

![ModchartDif](https://github.com/Martincraft7887/Things/blob/d28a721f6cac7e4c254f0c7ba41ea0541d63eee3/TutorialImages/ModchartDif.png)

You can also create other files such as:

modchart-normal.xml  
modchart-easy.xml  
modchart-myDifficulty.xml

The editor supports custom difficulties, so any name will work as long as it matches the song difficulty name.

# How to Add Shaders and Modifiers

Inside the editor:

Modchart > Timeline Items

![Here](https://github.com/Martincraft7887/Things/blob/44ab769bf22ee8c1e4cf9b59cac79423b0cd5bab/TutorialImages/Here.png)

From there you can add:

- Shaders
- Note modifiers
- FunkinModchartModifier

# Shaders Folder

Shaders must be placed in:

shaders/modchart

The default shaders are located in:

addons/ModchartEditor-PostProcessShader/shaders/modcharts

# Modifiers Folder

Modifiers are located in:

addons/ModchartEditor-GPUNotesModchart/modifiers

If you want to create new modifiers, you can use the shader:

notePerspective

as a base, since it is responsible for defining the behavior of the notes.

---

# 🇪🇸 Español

# Cómo descargar

Puedes descargar el proyecto presionando el botón verde Code y luego seleccionando Download ZIP o [dando click aqui](https://github.com/Martincraft7887/modcharteditor-cne-1.0.1/archive/refs/heads/main.zip)

Una vez descargado:

Extrae el archivo .zip
Coloca la carpeta dentro de mods en tu instalación de Codename Engine.

La ruta debería quedar así:

Codename Engine/mods/modcharts

Si deseas incluirlo dentro de tu propio mod, simplemente mueve el contenido de la carpeta modcharts a la carpeta de tu mod.

# Información adicional

Si no tienes conocimientos básicos de configuración en codename engine, puedes modificar el archivo:

data/config/modpack.ini

Desde ahí puedes:

Cambiar el nombre de la ventana
Modificar el ícono de la aplicación
Cambiar el ícono de Discord RPC


# Cómo usar

[Aqui](https://youtu.be/Or5PCoG4HkQ) puedes ver un video tutorial

Abre Codename Engine
Presiona TAB para seleccionar el mod (si no está activo)
Ve a:
Configuración
Miscellaneous Options
Activa el modo desarrollador

![This](https://github.com/Martincraft7887/Things/blob/44ab769bf22ee8c1e4cf9b59cac79423b0cd5bab/TutorialImages/This.png)

Regresa al menú principal
Presiona 7

![There](https://github.com/Martincraft7887/Things/blob/44ab769bf22ee8c1e4cf9b59cac79423b0cd5bab/TutorialImages/There.png)

Selecciona Modchart Editor (se encuentra hasta abajo)
Elige una canción de tu mod y comienza a editar


# Crear Modcharts por dificultad

Si quieres usar un Modchart diferente para cada dificultad:

Ve a la carpeta de la canción:

TuMod/songs/TuCancion/

Ahí encontrarás:

modchart.xml

![Modchart](https://github.com/Martincraft7887/Things/blob/d28a721f6cac7e4c254f0c7ba41ea0541d63eee3/TutorialImages/modchart.png)

Renómbralo según la dificultad:

modchart-hard.xml

![ModchartDif](https://github.com/Martincraft7887/Things/blob/d28a721f6cac7e4c254f0c7ba41ea0541d63eee3/TutorialImages/ModchartDif.png)

También puedes crear otros archivos como:

modchart-normal.xml
modchart-easy.xml
modchart-miDificultad.xml

El editor soporta dificultades personalizadas, así que cualquier nombre funcionará mientras coincida con el nombre de la dificultad de la canción.

# Cómo agregar shaders y modificadores

Dentro del editor:

Modchart > Timeline Items

![Here](https://github.com/Martincraft7887/Things/blob/44ab769bf22ee8c1e4cf9b59cac79423b0cd5bab/TutorialImages/Here.png)

Desde ahí podrás agregar:

- Shaders
- Modificadores de notas
- FunkinModchartModifier

# Carpeta de shaders

Los shaders deben ir en:

shaders/modchart

Los shaders por defecto se encuentran en:

addons/ModchartEditor-PostProcessShader/shaders/modcharts

# Carpeta de modifiers

Los modifiers se encuentran en:

addons/ModchartEditor-GPUNotesModchart/modifiers

Si quieres crear nuevos modifiers, puedes usar como base el shader:

notePerspective

ya que este es el encargado de definir el comportamiento de las notas.

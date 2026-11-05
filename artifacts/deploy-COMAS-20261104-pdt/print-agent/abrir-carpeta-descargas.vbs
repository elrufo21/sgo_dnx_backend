Option Explicit
Dim shell, fileSystem, folder
Set shell = CreateObject("WScript.Shell")
Set fileSystem = CreateObject("Scripting.FileSystemObject")
folder = shell.ExpandEnvironmentStrings("%SystemDrive%") & "\DNX\Descargas"
If fileSystem.FolderExists(folder) Then
  CreateObject("Shell.Application").Open folder
Else
  MsgBox "La carpeta de descargas de DNX aun no existe en esta PC.", vbInformation, "DNX"
End If

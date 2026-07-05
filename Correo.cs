using System;
using System.Collections.Generic;
using System.Net;
using System.Net.Mail;
namespace MegaRosita.Capa.Aplicacion
{
    public class Correo
    {
        Conexion xconexion = new Conexion();
        MailMessage Correos = new MailMessage();
        SmtpClient Envios = new SmtpClient();
        public Boolean EnviarCorreo(string Emisor, string Contraseña, string Receptor, string Contenido, string Cabezera, List<string> lstArchivos)
        {
            try
            {
                Correos.To.Clear();
                Correos.Body = "";
                Correos.Subject = "";
                Correos.Body = Contenido;
                Correos.Subject = Cabezera;
                Correos.IsBodyHtml = true;
                Correos.To.Add(Receptor.Trim());
                if (lstArchivos != null)
                {
                    //agregado de archivo
                    foreach (string archivo in lstArchivos)
                    {   //comprobamos si existe el archivo y lo agregamos a los adjuntos
                        if (System.IO.File.Exists(@archivo))
                        {
                            System.Net.Mail.Attachment Archivo = new System.Net.Mail.Attachment(@archivo);
                            Correos.Attachments.Add(Archivo);
                        }
                    }
                }
                Correos.From = new MailAddress(Emisor);
                Envios.Credentials = new NetworkCredential(Emisor, Contraseña);
                //ACA PODEMOS OBSERVAR NUESTRO HOST DE HOTMAIL.COM...
                Envios.Host = xconexion.xhost; //"smtp-mail.outlook.com";//
                Envios.Port = 587;
                Envios.EnableSsl = true;
                Envios.Send(Correos);
                return true;
            }
            catch (Exception ex)
            {
                ex.ToString();
                return false;
            }
        }
        public Boolean EnviarCorreoB(string Emisor, string Contraseña, string destino, string Contenido, string Cabezera, List<string> lstArchivos)
        {
            try
            {
                Correos.To.Clear();
                Correos.Body = "";
                Correos.Subject = "";
                Correos.Body = Contenido;
                Correos.Subject = Cabezera;
                Correos.IsBodyHtml = true;
                string[] destinatario = destino.Split(';');
                foreach (string destinos in destinatario)
                {
                    Correos.To.Add(new MailAddress(destinos));
                }
                if (lstArchivos != null)
                {
                    //agregado de archivo
                    foreach (string archivo in lstArchivos)
                    {   //comprobamos si existe el archivo y lo agregamos a los adjuntos
                        if (System.IO.File.Exists(@archivo))
                        {
                            System.Net.Mail.Attachment Archivo = new System.Net.Mail.Attachment(@archivo);
                            Correos.Attachments.Add(Archivo);
                        }
                    }
                }
                Correos.From = new MailAddress(Emisor);
                Envios.Credentials = new NetworkCredential(Emisor, Contraseña);
                Envios.Host = xconexion.xhost;//"smtp.gmail.com"; //"smtp-mail.outlook.com";//
                Envios.Port = 587;
                Envios.EnableSsl = true;
                Envios.Send(Correos);
                return true;
            }
            catch (Exception ex)
            {
                ex.ToString();
                return false;
            }
        }
    }
}

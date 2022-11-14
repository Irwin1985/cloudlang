

* ============================================================================= *
* PROGRAMA....: CLOUDLIB.PRG
* VERSION....: 0.0.1
* AUTOR.....: IRWIN RODRIGUEZ <rodriguez.irwin@gmail.com>
* FECHA.......: 08 November 2022, 17:04:39
* DESCRIPCIÓN...: API para consumir el servicio "cloudlang"
* HISTORIAL....:
* ============================================================================= *

* ============================================================================= *
* Convierte un string JSON en objetos compatibles con Visual Foxpro.
* cloudlang recibe el JSON y lo transpila a código Fox equivalente.
* ============================================================================= *
Function cloudlib_parseJSON(tcJSON)
	Local lcScript As Memo
	lcScript = _cloudlib_http_request("POST", "parse-json", tcJSON)
	Return Execscript(lcScript)
Endfunc

* ============================================================================= *
* Devuelve la versión actual del servicio cloudlang.
* ============================================================================= *
Function cloudlib_version
	Local lcResponse, loRegEx, loMatch, loGroups
	lcResponse = _cloudlib_http_request("GET", "version", "")
	If Empty(lcResponse)
		Return ''
	EndIf
	* Extract the version using RegEx.
	loRegEx = Createobject("VBScript.RegExp")
	loRegEx.IgnoreCase = .T.
	loRegEx.Global = .T.
	loRegEx.Pattern = '("version":)("[^"]+")'
	loMatch = loRegEx.Execute(lcResponse)
	If Type('loMatch') == 'O'
		loSubMatch = loMatch.Item[0]
		loGroups   = loSubMatch.SubMatches
		lcResponse = loGroups.Item[1]
		Release loGroups, loSubMatch, loMatch
	Endif
	Release loRegEx
	Return lcResponse
Endfunc

* ============================================================================= *
* Ejecuta una consulta de solo lectura a un servidor en la nube.
* tcKey: el identificador único de la conexión, si no lo tiene entonces debe
* 		 invocar antes a "cloudlib_create_connection()"
* tcQuery: la consulta a ejecutar (queda de su parte revisar que no contenga
* 		   errores de sintaxis ni macros sin ejecutar.
* tcCursor: el cursor resultante. Puede dejar en blanco y se le devolverá
* 			el array en formato JSON resultado de la consulta.
* NOTA: si no existe la aplicación JSONFox.app en su PATH entonces devolverá
* 		solamente el array en formato JSON.
* ============================================================================= *
Function cloudlib_sqlexec(tcKey, tcQuery, tcCursor)
	Local lcBody As Memo, lcResult as memo, loConnection	
	loConnection = _cloudlib_get_connection_object(tcKey)
	If IsNull(loConnection)
		MessageBox('No existe una conexión activa para la clave: ' + tcKey, 48, 'CloudLib')
		Return
	EndIf

	Text to lcBody noshow textmerge pretext 15
		{
			"host": "<<loConnection.host>>",
			"port": "<<loConnection.port>>",
			"user": "<<loConnection.user>>",
			"password": "<<loConnection.password>>",
			"database": "<<loConnection.database>>",
			"query": "<<tcQuery>>"
		}
	endtext

	lcResult = _cloudlib_http_request("POST", "execute-custom-query", lcBody)
	If !Empty(lcResult)
		&& TODO(irwin): considerar inyectar la dependencia del JSON.
		Local lcJSONFoxPath
		lcJSONFoxPath = FullPath("JSONFox.app")		
		If File(lcJSONFoxPath) and !Empty(tcCursor)
			try
				Do (lcJSONFoxPath)
				_screen.json.JSONToCursor(lcResult, tcCursor, Set("Datasession"))
			Catch
			EndTry
			If Used(tcCursor)
				Return Space(1)
			EndIf
		EndIf
	EndIf
	Return lcResult
Endfunc

* ============================================================================= *
* Crea una credencial de acceso para conectarse a un servidor remoto.
* Devuelve un identificador único que deberá pasarse como parámetro en cada
* función que requiera solicitar acceso al servidor requerido.
* NOTA: puedes crear tantas conexiones a distintos servidores como necesites.
* <<El servidor compatible por el momento es MariaDB/MySQL>>
* ============================================================================= *
Function cloudlib_create_connection(tcHost, tcPort, tcUser, tcPassword, tcDatabase)
	_cloudlib_create_connection_pool_object()
	
	Local loConnection, lcKey
	loConnection = CreateObject('Empty')
	=AddProperty(loConnection, 'host', tcHost)
	=AddProperty(loConnection, 'port', tcPort)
	=AddProperty(loConnection, 'user', tcUser)
	=AddProperty(loConnection, 'password', tcPassword)
	=AddProperty(loConnection, 'database', tcDatabase)

	lcKey = _cloudlib_new_guid()
	_screen._cloudlib_connection_pool.add(loConnection, lcKey)

	Return lcKey
EndFunc

* ============================================================================= *
* Envía un POST al servicio cloudlang con un JSON como cuerpo.
* NOTA: <<ESTA FUNCIÓN ES PRIVADA>>
* ============================================================================= *
Function _cloudlib_http_request(tcMethod, tcEndPoint, tcBody)
	Local xmlHTTP As "Microsoft.XMLHTTP", lcURL As String, lcBody As Memo, lcResponse As Memo, nSeg As Number

	*-- Definir las constantes para la evaluación de resultados.
	#Define HTTP_STATUS_OK        200
	#Define HTTP_COMPLETED        4
	#Define HTTP_OPEN             1
	#Define CR                    Chr(13)
	#Define MSGBOX_INFO           64
	#Define MSGBOX_WARNING        48
	#Define TYPE_OBJECT           "O"
	#Define TIME_OUT              120 && Tiempo de espera máximo para la respuesta.

	lcServer = "https://cloudlang.herokuapp.com"
	* <<DEBUG>>
	* lcServer = "http://localhost:3001"
	* <<DEBUG>>

	lcURL = lcServer + "/" + tcEndPoint
	xmlHTTP = Createobject("Microsoft.XMLHTTP")

	If Type("xmlHTTP") <> TYPE_OBJECT
		Wait "No se pudo crear el objeto (XMLHTTP)." Window Nowait
		Return
	Endif

	xmlHTTP.Open(tcMethod, lcURL, .F.)
	If xmlHTTP.readyState <> HTTP_OPEN
		Wait "No se pudo procesar su solicitud." Window Nowait
		Return
	Endif
	xmlHTTP.setRequestHeader("Content-Type","application/json")
	If !Empty(tcBody)
		xmlHTTP.Send(tcBody)
	Else
		xmlHTTP.Send()
	Endif
	nSeg = Seconds() + TIME_OUT
	Do While Seconds() <= nSeg
		Wait "Esperando respuesta del servidor, tiempo restante {" + Str(nSeg - Seconds()) + "} Seg." Window Nowait
		If xmlHTTP.readyState <> HTTP_OPEN
			*-- Hubo una respuesta
			Exit
		Endif
	Enddo
	Wait Clear

	If xmlHTTP.readyState == HTTP_COMPLETED And xmlHTTP.Status == HTTP_STATUS_OK
		lcResponse = xmlHTTP.responseText
	Else
		lcResponse = ''
		Wait "No se pudo procesar su solicitud." Window Nowait
	Endif

	Release xmlHTTP

	Return lcResponse
Endfunc

* ============================================================================= *
* Crea un diccionario con las conexiones creadas por el usuario.
* NOTA: <<ESTA FUNCIÓN ES PRIVADA>>
* ============================================================================= *
Function _cloudlib_create_connection_pool_object
	If Type('_screen._cloudlib_connection_pool') = 'O'
		Return
	EndIf
	=addproperty(_screen, '_cloudlib_connection_pool', CreateObject('Collection'))	
EndFunc

* ============================================================================= *
* Devuelve un identificador único.
* NOTA: <<ESTA FUNCIÓN ES PRIVADA>>
* ============================================================================= *
Function _cloudlib_new_guid
	Local loGuid
	loGuid = CreateObject("scriptlet.typelib")

	Return substr(loGuid.GUID, 2, 36)
EndFunc

* ============================================================================= *
* Devuelve el objeto con las credenciales de acceso a un servidor remoto.
* NOTA: <<ESTA FUNCIÓN ES PRIVADA>>
* ============================================================================= *
Function _cloudlib_get_connection_object(tcKey)
	
	Local lnIndex
	lnIndex = _screen._cloudlib_connection_pool.GetKey(tcKey)
	If lnIndex <= 0
		Return .null.
	EndIf
	
	Return _screen._cloudlib_connection_pool.Item(lnIndex)
EndFunc
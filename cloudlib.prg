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
	lcScript = cloudlib_http_request("POST", "parse-json", tcJSON)
	Return Execscript(lcScript)
Endfunc

* ============================================================================= *
* Devuelve la versión actual del servicio cloudlang.
* ============================================================================= *
Function cloudlib_version
	LOCAL lcResponse, loRegEx, loMatch, loGroups
	lcResponse = cloudlib_http_request("GET", "version", "")
	* Extract the version using RegEx.
	loRegEx = Createobject("VBScript.RegExp")
	loRegEx.IgnoreCase = .T.
	loRegEx.Global = .T.
	loRegEx.Pattern = '("version":)("[^"]+")'	
	loMatch = oRegEx.Execute(lcResponse)
	IF TYPE('loMatch') == 'O'
		loSubMatch = loMatch.Item[0]
		loGroups   = loSubMatch.SubMatches
		lcResponse = loGroups.Item[1]		
		RELEASE loGroups, loSubMatch, loMatch
	ENDIF
	RELEASE loRegEx
	RETURN lcResponse
Endfunc

* ============================================================================= *
* Envía un POST al servicio cloudlang con un JSON como cuerpo.
* NOTA: esta función es para uso interno solamente.
* ============================================================================= *
Function cloudlib_http_request(tcMethod, tcEndPoint, tcBody)
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
	IF !EMPTY(tcBody)
		xmlHTTP.Send(tcBody)
	ELSE
		xmlHTTP.Send()
	ENDIF
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
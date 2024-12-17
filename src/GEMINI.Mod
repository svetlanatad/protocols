MODULE GEMINI;

IMPORT IntStr := oocIntStr, Strings, Files, Out, Internet, strTypes, strUtils, dynamicarray, http, mbedtls;

CONST
  defName = "defaultname.gmi";
  defEOL = "0DX0AX"; (* CRLF end of line *)

TYPE
  transport* = POINTER TO transportDesc;
  transportDesc* = RECORD END;

  bsdSocket* = POINTER TO bsdSocketDesc;
  bsdSocketDesc = RECORD(transportDesc)
    socket : Internet.Socket
  END;

   TLSSocket = POINTER TO TLSSocketDesc;
   TLSSocketDesc = RECORD(transportDesc)
     netContext* : ARRAY 512 OF CHAR;    (* 4 bytes are enough *)
     sslContext* : ARRAY 512 OF CHAR;   (* 472 bytes *)
     sslConf*    : ARRAY 512 OF CHAR;   (* 400 bytes *)
   END;
    
  

  Client* = POINTER TO ClientDesc;

  ClientDesc* = RECORD
    entropy*  : ARRAY 40000 OF CHAR; (* 1080 on x86_64, 37000 on armhl *)
    ctrDrbg*  : ARRAY 512 OF CHAR;   (* 392 bytes *)
    cacert*   : ARRAY 1024 OF CHAR;  (* 616 bytes *)
    crtpath*   : ARRAY 256 OF CHAR; 
    pers*     : ARRAY 128 OF CHAR;

  setCertPath*  : PROCEDURE (VAR h: Client; path: ARRAY OF CHAR);
   setPers*      : PROCEDURE (VAR h: Client; pers: ARRAY OF CHAR);
      Init*      : PROCEDURE (VAR h: Client);


    host*, port*, path*: strTypes.pstring;
    connectionFlag*: BOOLEAN;
    trn*: transport;
    rspnBody*: strTypes.pstring;
    header-: strTypes.pstring;
    mimetype-: strTypes.pstring;
    statusCode: LONGINT;
    statusRead-: ARRAY 64 OF CHAR;
    rspnFirstLine*: strTypes.pstring;
    contentLength*: LONGINT;
    eol*: ARRAY 2 OF CHAR;
    null*: ARRAY 1 OF CHAR;
    dyno: dynamicarray.dynamicarray;
    Create*: PROCEDURE(host, port, path: ARRAY OF CHAR): Client;
    Get*: PROCEDURE(gemini: Client): strTypes.pstring;
    clearState*: PROCEDURE(VAR gemini: Client);
    Connect*: PROCEDURE(VAR gemini: Client): BOOLEAN;
    Disconnect*: PROCEDURE(VAR gemini: Client);
    Write*: PROCEDURE(VAR gemini: Client; request: ARRAY OF CHAR): BOOLEAN;
    Read*: PROCEDURE(VAR gemini: Client; VAR buf: ARRAY OF CHAR; VAR toRead: LONGINT): BOOLEAN;
    Dynomaker: PROCEDURE(VAR gemini: Client): dynamicarray.dynamicarray;
    Save*: PROCEDURE(VAR gemini: Client; name: ARRAY OF CHAR): dynamicarray.dynamicarray;
(*use reader*) 

END;


PROCEDURE init(VAR gemini: Client);
BEGIN
  IF gemini^.trn IS TLSSocket THEN
    mbedtls.init(gemini^.trn(TLSSocket).netContext, gemini^.trn(TLSSocket).sslContext, gemini^.trn(TLSSocket).sslConf, gemini^.entropy, gemini^.ctrDrbg, gemini^.cacert, gemini^.pers, gemini^.crtpath)
  END;
END init;

PROCEDURE setcertpath(VAR gemini: Client; path: ARRAY OF CHAR);
BEGIN
  COPY(path, gemini^.crtpath);
END setcertpath;

(* change TLSCLient to Client *)
(* Personalization data (Device specific identifiers) *)
PROCEDURE setpers(VAR gemini: Client; str: ARRAY OF CHAR);
BEGIN
  COPY(str, gemini^.pers)
END setpers;


PROCEDURE connector(VAR gemini: Client):BOOLEAN;
VAR i: LONGINT;
BEGIN
  gemini.connectionFlag := FALSE;
  IF gemini^.trn IS TLSSocket THEN
    i := mbedtls.connect(gemini^.trn(TLSSocket).netContext, gemini^.trn(TLSSocket).sslContext, gemini^.trn(TLSSocket).sslConf, gemini(Client)^.entropy, gemini(Client)^.ctrDrbg, gemini(Client)^.cacert, gemini^.host^, gemini^.port^);
    IF i = 0 THEN gemini^.connectionFlag := TRUE ELSE gemini^.connectionFlag := FALSE END;
  ELSE
    Out.String("gemini client is not initialized with tls socket"); Out.Ln;
    HALT(5);
  END;
  RETURN gemini^.connectionFlag
END connector;

PROCEDURE disconnector(VAR gemini: Client);
VAR
  i: LONGINT;
BEGIN
  IF gemini IS Client THEN
    i := mbedtls.disconnect(gemini^.trn(TLSSocket).netContext, gemini^.trn(TLSSocket).sslContext, gemini^.trn(TLSSocket).sslConf, gemini(Client)^.entropy, gemini(Client)^.ctrDrbg);
  ELSE
    Out.String("gemini client is not initialized with tls socket"); Out.Ln;
    HALT(5);
  END;
END disconnector;



PROCEDURE reader*(VAR gemini: Client; VAR buf: ARRAY OF CHAR; toRead: LONGINT): BOOLEAN;
VAR
  len: LONGINT;
  r: LONGINT;
BEGIN
    r := -1;
  IF gemini^.trn IS TLSSocket THEN
    IF toRead = -1 THEN len := LEN(buf)-1 ELSE len := toRead END;
    r := mbedtls.read(gemini^.trn(TLSSocket).sslContext, buf, len);
  ELSE
    Out.String("gemini client is not initialized with tls socket"); Out.Ln;
    HALT(5);
  END;
  RETURN (r > 0)
END reader;

PROCEDURE writer(VAR gemini: Client; buf: ARRAY OF CHAR):BOOLEAN;
VAR
  len: LONGINT; r: LONGINT;
BEGIN
  r := -1;
  IF gemini^.trn IS TLSSocket THEN
    len := Strings.Length(buf);
    r := mbedtls.write(gemini^.trn(TLSSocket).sslContext, buf, len);
  ELSE
    Out.String("gemini client is not initialized with tls socket"); Out.Ln;
    HALT(5);
  END;
  RETURN r = 0;
END writer;


PROCEDURE readBuf(VAR gemini: Client; VAR buf: ARRAY OF CHAR; VAR haveRead: LONGINT): BOOLEAN;
VAR
  r: LONGINT;
BEGIN
  gemini^.connectionFlag := FALSE;
  IF gemini^.trn IS TLSSocket THEN
    r := mbedtls.readBuf(gemini^.trn(TLSSocket).netContext, gemini^.trn(TLSSocket).sslContext, buf, haveRead);
    IF r <= 0 THEN
      gemini^.connectionFlag := FALSE;
      haveRead := 0;
    ELSE
      gemini^.connectionFlag := TRUE
    END;
   ELSE
    Out.String("gemini client is not initialized with tls socket"); Out.Ln;
    HALT(5);
  END;
  RETURN gemini^.connectionFlag
END readBuf;

(* we have init, setcertpath, setpers, connector, disconnector, writer, reader, readBuf *) 




PROCEDURE clearState*(VAR gemini: Client);
BEGIN
  gemini^.mimetype := NIL;
  gemini^.rspnBody := NIL;
  gemini^.header := NIL;
  gemini^.rspnFirstLine := NIL;
  gemini^.contentLength := 0;
END clearState;

PROCEDURE dynomaker(VAR gemini: Client): dynamicarray.dynamicarray;
BEGIN 
RETURN dynamicarray.Create();
END dynomaker;

PROCEDURE saver(VAR gemini: Client; name: ARRAY OF CHAR): dynamicarray.dynamicarray;
BEGIN
RETURN dynamicarray.writetofile(gemini^.dyno, name);
END saver;
(*
PROCEDURE connector(VAR gemini: Client): BOOLEAN;
BEGIN
  gemini^.connectionFlag := FALSE;
  IF gemini^.trn IS bsdSocket THEN
    gemini^.connectionFlag := Internet.Connect(gemini^.host^, gemini^.port^, gemini^.trn(bsdSocket).socket);
  ELSE
    Out.String("Gemini client is not initialized with bsd socket"); Out.Ln;
    HALT(5);
  END;
  RETURN gemini^.connectionFlag;
END connector;
*)
(*
PROCEDURE disconnector(VAR gemini: Client);
BEGIN
  IF gemini^.trn IS bsdSocket THEN
    Internet.Disconnect(gemini^.trn(bsdSocket).socket);
  ELSE
    Out.String("Gemini client is not initialized with bsd socket"); Out.Ln;
    HALT(5);
  END;
END disconnector;
*)

(*
PROCEDURE writer(VAR gemini: Client; request: ARRAY OF CHAR): BOOLEAN;
BEGIN
  IF gemini^.trn IS bsdSocket THEN
    RETURN Internet.Write(gemini^.trn(bsdSocket).socket, request);
  (*b := Internet.Write(gemini^.trn(bsdSocket).socket, req^);*)
  ELSE
    Out.String("Gemini client is not initialized with bsd socket"); Out.Ln;
    RETURN FALSE;
  END;
END writer;
*)

(*
PROCEDURE readbuffer(VAR gemini: Client; VAR buf: ARRAY OF CHAR; VAR i: LONGINT): BOOLEAN;
BEGIN
IF gemini^.trn IS bsdSocket THEN 
   RETURN Internet.ReadBuf(gemini^.trn(bsdSocket).socket, buf, i); 
ELSE 
Out.String("gemini is not inintialized with bsdSocket");Out.Ln;
RETURN FALSE;
END
END readbuffer;
*)

(*
PROCEDURE reader(VAR gemini: Client; VAR buffer: ARRAY OF CHAR): BOOLEAN;
BEGIN
  IF gemini^.trn IS bsdSocket THEN
    RETURN Internet.Read(gemini^.trn(bsdSocket).socket, buffer);
  ELSE
    Out.String("Gemini client is not initialized with bsd socket"); Out.Ln;
    RETURN FALSE;
  END;
END reader;
*)


PROCEDURE buildRequest*(gemini: Client): strTypes.pstring;
VAR
  req: strTypes.pstring;
  len: INTEGER;
BEGIN
  len := Strings.Length(gemini^.host^) + Strings.Length(gemini^.path^) + 10; (* SP and EOL *)
  NEW(req, len);
  (* CHECK *) 
  (* Build the request line *)
  COPY("gemini://", req^);
  Strings.Append(gemini^.host^, req^);
  (*COPY(gemini^.host^, req^);*)
  Strings.Append(gemini^.path^, req^);
  (*Strings.Append(" ", req^);*)
  (*                ^ ask inky: I keep changing this and the next line to Append " 0", req^ and it gives either the gemini protocol or # the gemini protocol*)
  Strings.Append(gemini^.eol, req^);

  RETURN req;
END buildRequest;

PROCEDURE getMimetype(VAR gemini: Client;  VAR str: ARRAY OF CHAR);
VAR 
i, pos: INTEGER;
foundspace, b: BOOLEAN;
mim: strTypes.pstring;
hdr: ARRAY 244 OF CHAR;
buf: ARRAY 2 OF CHAR;
BEGIN
  Out.String("entered getMimetype"); Out.Ln;
  NEW(mim, LEN(str));
  pos := -1;
  foundspace := FALSE;
  i := 0;
  COPY("", hdr);
  REPEAT 
    IF (str[i] = " ") THEN 
       IF ~foundspace THEN 
	   foundspace := TRUE;
	   pos := i + 1;
       ELSE 
	   IF pos # -1 THEN 
    
 
                b := Internet.ReadBytes(gemini^.trn(bsdSocket).socket, buf, 1);
                IF b THEN 
		    IF buf[0] # 0DX THEN 
		        hdr[pos] := buf[0];
		    END;
		Out.String("have read one byte: "); Out.Char(buf[0]);Out.Ln;
                ELSE 
 		Out.String("failed to read"); Out.Ln;
                END;     

	   END;
       Out.String("did not find space"); Out.Ln;
       END;
    END;
  INC(i);    
  UNTIL buf[0] = 0DX;
  COPY(hdr, mim^); 
  IF mim # NIL THEN 
    gemini^.mimetype := mim;
    Out.String("assigned mimetype"); Out.String(mim^); Out.Ln;
  ELSE 
    Out.String("could not assign"); Out.Ln;
  END;

END getMimetype;


PROCEDURE parseHeader(VAR gemini: Client; VAR str: ARRAY OF CHAR);
VAR 
  i, statuscodeint: LONGINT;
  res: SHORTINT;
  statuscode: ARRAY 4 OF CHAR;
BEGIN 
    Out.String("header is: '"); Out.String(str); Out.String("'"); Out.Ln;
  i := 0;
  res := 0;
 (* maybe use internet.readbytes? *) (*confusion*)
  statuscode := "";
  REPEAT 
      IF (str[i] >= '0') & (str[i] <= '9') THEN 

      IF (str[i + 1] >= '0') & (str[i+1] <= '9') THEN 
         statuscode[i] := str[i]; 
         statuscode[i+1] := str[i+1]; 
         statuscode[3] := 0X;
      ELSE
         statuscode[i] := str[i]; 
         statuscode[2] := 0X;
      END;
      ELSE
         Out.String("status code should be a number"); Out.Ln;   
      END;
      INC(i);
  UNTIL i = LEN(str);
  (*check if single or double digit*)
  IntStr.StrToInt(statuscode, statuscodeint, res);
  IF (statuscodeint < 10) OR (statuscodeint > 69) THEN 
     Out.String("invalid status code, it should be between ten and sixty nine"); Out.Ln; HALT(6);
  END;
  Out.String("assigning the status code to the client"); Out.Ln;
  (*gemini^.statusCode := statuscodeint;*)
  Out.String("status code: "); Out.Int(gemini^.statusCode, 0); Out.Ln;
  IF (statuscodeint >= 10) & (statuscodeint <= 19) THEN 
   
    gemini^.statusCode := 10;
    gemini^.statusRead := "Input expected"; 
  ELSIF (statuscodeint > 19) & (statuscodeint < 30) THEN 
    gemini^.statusRead := "Success";
    gemini^.statusCode := 20;
    getMimetype(gemini, str);
  ELSIF (statuscodeint >= 30) & (statuscodeint < 40) THEN 
    gemini^.statusCode := 30;
    gemini^.statusRead := "Redirection";
  ELSIF (statuscodeint >= 40) & (statuscodeint < 50) THEN 
    gemini^.statusCode := 40;
    gemini^.statusRead := "Temporary failure";
  ELSIF (statuscodeint >= 50) & (statuscodeint < 60) THEN 
    gemini^.statusCode := 50;
    gemini^.statusRead := "Permanent failure";
  ELSIF (statuscodeint >= 60) & (statuscodeint <= 69) THEN 
    gemini^.statusCode := 60;
    gemini^.statusRead := "Client certificates";
  END;
  Out.String("assigned the status read to the client"); Out.String(gemini^.statusRead); Out.Ln;
 
END parseHeader;


PROCEDURE zeroBuf(VAR str: ARRAY OF CHAR);
VAR i: INTEGER;
BEGIN 
  i := 0;
  REPEAT
  str[i] := 0X;
  INC(i);
  UNTIL i = LEN(str)
END zeroBuf;

PROCEDURE readTillCRLF(gemini: Client);
VAR
  buf: ARRAY 2 OF CHAR;
  hdr: ARRAY 256 OF CHAR;
  b: BOOLEAN;
  i: INTEGER;
BEGIN
  COPY("", hdr); i := 0;
  REPEAT
    b := Internet.ReadBytes(gemini^.trn(bsdSocket).socket, buf, 1);
      IF b THEN
        IF buf[0] # 0DX THEN
          hdr[i] := buf[0];
          INC(i);
        END;
        Out.String("have read one byte: '"); Out.Char(buf[0]);
        Out.String("'"); Out.Ln;
      ELSE
         Out.String("failed to read"); Out.Ln; HALT(2);
      END;
  UNTIL buf[0] = 0DX;
  hdr[i] := 0X;
  b := Internet.ReadBytes(gemini^.trn(bsdSocket).socket, buf, 1);
  IF b THEN
    IF buf[0] # 0AX THEN
      Out.String("0AX expected, got: "); Out.Int(ORD(buf[0]), 0);
      Out.Ln; HALT(1);
    END;
  ELSE
    Out.String("failed to read"); Out.Ln; HALT(3)
  END;
  NEW(gemini^.header, Strings.Length(hdr)+1);
  COPY(hdr, gemini^.header^);
  parseHeader(gemini, gemini^.header^);
END readTillCRLF;

PROCEDURE get*(gemini: Client): strTypes.pstring;
VAR
  req: strTypes.pstring;
  buf: ARRAY 15 OF CHAR;
  (*ok so apparentl this k logic works iff reading chunk size is 16*)
  (*so now it works with 15 bytes but doesnt read # in 16 bytes*)
  i, k: LONGINT;
  b: BOOLEAN;
  responseArr: dynamicarray.dynamicarray; 
  (*header: dynamicarray.dynamicarray;*)
BEGIN
  gemini^.clearState(gemini);

  gemini^.connectionFlag := gemini.Connect(gemini);
  IF ~gemini^.connectionFlag THEN
    Out.String("Connection failed"); Out.Ln;
    HALT(5);
  END;

  req := buildRequest(gemini);
  b := writer(gemini, req^);

  IF b THEN
    gemini^.dyno := dynomaker(gemini);
    responseArr := dynamicarray.Create();
    i := 0; k := 0;
    readTillCRLF(gemini);
    REPEAT
      zeroBuf(buf);
      (*b := Internet.ReadBuf(gemini^.trn(bsdSocket).socket, buf, i);*)
         (*ask inky: when i implement it with oop with the line of code next, it incorrectly reads the request*)
       b := readBuf(gemini, buf, i);
                (* ^ think later this is too weird*)
      
      Out.String("-------------"); Out.Ln;
      Out.String(buf); Out.Ln;
      Out.String("-------------"); Out.Ln;
     
      (* 
      IF k = 0 THEN
         (*idea
          create a dyn array here 
          append the buf here 
          store it to a global field of gemini
          write toa seperate file to read
         *)
         (*gemini^.header := dynomaker(gemini);*)
	 (*gemini^.header.appender(gemini^.header, buf);*)
	 header.appender(header, buf);
         NEW(gemini^.headerbody, LEN(buf));
	 COPY(header^.content^, gemini^.headerbody^);
         (*parseHeader(gemini, gemini^.headerbody^);*)
         responseArr.appender(responseArr, "");
         gemini^.dyno.appender(gemini^.dyno, "");
         Out.String("content of the respons arr during first iter"); Out.String(responseArr.content^); Out.Ln;

        Out.String("Tried to skip appending"); Out.Ln;
      ELSE
      *)
        responseArr.appender(responseArr, buf);
        gemini^.dyno.appender(gemini^.dyno, buf);
      (*END;*)
      Out.String("Response array contents so far:"); Out.Ln;
      Out.String("-------------------------------------------------"); Out.Ln;
      Out.String(responseArr^.content^); Out.Ln;
      Out.String(gemini^.dyno^.content^); Out.Ln;
      Out.String("-------------------------------------------------"); Out.Ln;

      INC(k);
    UNTIL ~b OR (i = 0);
    NEW(gemini^.rspnBody, LEN(gemini^.dyno^.content^)); 
    (*NEW(gemini^.rspnBody, LEN(responseArr^.content^));*)
    COPY(gemini^.dyno^.content^, gemini^.rspnBody^);
    (*COPY(responseArr^.content^, gemini^.rspnBody^);*)
  ELSE
    Out.String("Failed to send request"); Out.Ln;
    HALT(5);
  END;
  
  gemini.Disconnect(gemini);
  (*parseHeader(gemini, gemini^.headerbody^);*)
  (*Out.String("HEADER CONTENT##################################################################"); Out.String(header^.content^); Out.Ln;
  Out.String("HEADER CONTENT-----------------------------------------------------------------"); Out.String(gemini^.headerbody^); Out.Ln;
  Out.String("STATUS CODE #######################################################"); Out.Int(gemini^.statusCode, 0); Out.Ln;*)
  (*gemini^.dyno := saver(gemini, "H.txt");*)
  (*dynamicarray.writetofile(responseArr, "HULLO.txt");*)
  (*gemini^.header := saver(gemini, "header.txt");*) 
  RETURN gemini^.rspnBody;
END get;




PROCEDURE Create*(host, port, path: ARRAY OF CHAR): Client;
VAR
  gemini: Client;
  socket: TLSSocket;
BEGIN
  NEW(gemini);
  gemini^.eol[0] := 0DX; gemini^.eol[1] := 0AX; gemini^.null[0] := 0X;

  (* Initialize fields *)
  strUtils.string2pstring(host, gemini^.host);
  strUtils.string2pstring(port, gemini^.port);
  strUtils.string2pstring(path, gemini^.path);

  (* Set default values *)
  gemini^.contentLength := 0;

  (* Assign methods *)
  gemini^.Get := get;
  gemini^.Create := Create;
  gemini^.clearState := clearState;

  NEW(socket);
  gemini^.trn := socket;
  gemini.Connect := connector;
  gemini.Disconnect := disconnector;
  (*gemini.Read := reader;*)
  gemini.Write := writer;
  gemini^.Dynomaker := dynomaker;
  gemini^.Save := saver;

  gemini.setCertPath := setcertpath; (* change to gemini *)
  gemini.setPers     := setpers;

  gemini.setCertPath(gemini, "/etc/ssl/certs/ca-certificates.crt");
  (*hs.setCertPath(hs, "./isrgrootx1.pem");*)
  (*hs.setCertPath(hs, "./ca-certificates.crt");*)

  gemini.setPers(gemini, "oberon_mbedtls_client");
  gemini.Init := init;


  RETURN gemini;
END Create;

END GEMINI.

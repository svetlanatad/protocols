MODULE dynamicarray;

IMPORT Out, Files;

TYPE dynamicarray* = POINTER TO DynamicarrayDesc;
dynarray* = RECORD
END;

DynamicarrayDesc* = RECORD(dynarray)
	(*size is how many elements*)
	size-: LONGINT;
	(*capacity is how many elements it can hold*)
	capacity-: LONGINT; 
	content-: POINTER TO ARRAY OF CHAR;
        appender-: PROCEDURE (a: dynamicarray; str: ARRAY OF CHAR);
END;


PROCEDURE writetofile*(arr: dynamicarray; name: ARRAY OF CHAR);
VAR 
file: Files.File;
r: Files.Rider;
i: LONGINT;
BEGIN
file := Files.New(name);
IF file  # NIL THEN 
   Files.Set(r, file, 0);
   i := 0;
   REPEAT
     Files.Write(r, arr^.content^[i]);
     INC(i);
   UNTIL i = arr^.capacity;
ELSE 
   Out.String("file was nil"); Out.Ln;
END;
Files.Register(file);
Files.Close(file);
END writetofile;

PROCEDURE copy(VAR src, dst: ARRAY OF CHAR);
(*if the content is null just overwrite else write after*)
VAR 
  i: LONGINT;
BEGIN
   IF LEN(src) <= LEN(dst) THEN
     i := 0;
       Out.String("good. source length is smaller than or equal to the destination length"); Out.Ln;
    
     REPEAT
       IF src[i] = 0X THEN 
         dst[i] := src[i];
         Out.String("curr char: "); Out.Char(dst[i]); Out.Ln;
         Out.String("overwritten something from source to dest as it was null"); Out.Ln;
        ELSE (*if it is not null *)
	 Out.String("current iter count: "); Out.Int(i,0); Out.Ln;
         dst[i] := src[i];
         Out.String("curr char: "); Out.Char(dst[i]); Out.Ln;
         Out.String("copied something from source to the end of the arr as it was not null"); Out.Ln;
     END;
     INC(i);
     UNTIL i = LEN(src);
     Out.String("Whats the iterator count now? The size? Source LEN: "); Out.Int(i, 0); Out.Ln;
   ELSE
      Out.String("copy source, destination: error: destination length needs to be >= src length"); Out.Ln; HALT(0);
   END;
   
END copy;

PROCEDURE ReallocAndAppendinky(arr: dynamicarray; str: ARRAY OF CHAR);
(*should i copy the str into tmp or into the array*)
VAR
  tmp: POINTER TO ARRAY OF CHAR;
BEGIN
  Out.String("current array content len: "); Out.Int(LEN(arr^.content^), 0); Out.Ln;
  NEW(tmp, LEN(arr^.content^));
  Out.String("allocated memory for tmp arr with arr content size"); Out.Ln;
  copy(arr^.content^, tmp^);
  Out.String("copied the arr content into the tmp content"); Out.Ln;
  NEW(arr^.content, LEN(tmp^) + LEN(str) + 1); 
  (*arr^.size := LEN(tmp^) + LEN(str);*)
  arr^.size := LEN(str);
  arr^.capacity := arr^.capacity + LEN(str) + 1;
  (* Content and capacity size should be the same?*)
  Out.String("Array size now: "); Out.Int(arr^.size, 0); Out.Ln;
  Out.String("LEN array content size: "); Out.Int(LEN(arr^.content^), 0); Out.Ln;
  Out.String("Array capacitynow: "); Out.Int(arr^.capacity, 0); Out.Ln;
  copy(tmp^, arr^.content^);
  Out.String("copied the tmp content bakc into the array content after reallocation"); Out.Ln;
  Out.String("trying to copy the string into the array"); Out.Ln;
  copy(str, arr^.content^);
  Out.String("trying to assign 0X to the last element of arr"); Out.Ln;
  arr^.content^[LEN(tmp^) + LEN(str)] := 0X; Out.String("assigned complete"); Out.Ln
END ReallocAndAppendinky;

PROCEDURE copylarr0t(VAR src: ARRAY OF CHAR; VAR dst: ARRAY OF CHAR; VAR start: LONGINT);
VAR 
i: LONGINT;
j: LONGINT;
s: LONGINT;
d: LONGINT;
BEGIN
i := start;
j := 0;
s := LEN(src);
d := LEN(dst);

Out.String("len of src is: "); Out.Int(s, 0); Out.Ln;
Out.String("len of dst is: "); Out.Int(d, 0); Out.Ln;

IF i = 0 THEN 
   REPEAT 
     dst[i] := src[i];
     INC(i);
   UNTIL i = LEN(src) - 1;
ELSE 
   Out.String("current index i am trying to assign is: "); Out.Int(i, 0); Out.Ln;
   REPEAT
     (*Out.String("curr char in dst is: "); Out.Char(dst[i]); Out.Ln;

     Out.String("curr char in src is: "); Out.Char(src[j]); Out.Ln;*)
     dst[i] := src[j];
     INC(i);
     INC(j);
   UNTIL i = LEN(dst) - 2;
END;


(*
IF s > d THEN
  REPEAT 
    dst[i] := src[i];
    INC(i);
  UNTIL i = LEN(src) - 1;
ELSE 
   REPEAT 
     dst[i] := src[i];
     INC(i);
   UNTIL i = LEN(dst) - 1;
END;*)
Out.String("The last index probably is: "); Out.Int(i, 0); Out.Ln;

dst[i] := 0X;
(*i dont get how to handle the logic of indexing of copying :( *)

END copylarr0t;


PROCEDURE ReallocAndAppend(arr: dynamicarray; str: ARRAY OF CHAR);
VAR 
tmp: POINTER TO ARRAY OF CHAR;
i: LONGINT;

BEGIN
i := 0;
NEW(tmp, LEN(arr^.content^));
Out.String("allocated array content length memory space to tmp array"); Out.Ln;
copylarr0t(arr^.content^, tmp^, i);
Out.String("copied the content into the tmp array"); Out.Ln;
NEW(arr^.content, LEN(tmp^) + LEN(str) + 1);
arr^.size := (LEN(tmp^) + LEN(str) - 2);
arr^.capacity := (arr^.size + 1);
Out.String("The size of the arr: "); Out.Int(arr^.size, 0); Out.Ln;
Out.String("The capacity of the arr: "); Out.Int(arr^.capacity, 0); Out.Ln;
Out.String("allocated new memory for array content which is len of tmp + len of str + 1");Out.Ln;
copylarr0t(tmp^, arr^.content^, i);
Out.String("copied the tmp content back into the array from the first index"); Out.Ln;
i := (LEN(tmp^) - 1);
Out.Int(i, 0); Out.String(" is the current iterator"); Out.Ln;
copylarr0t(str, arr^.content^, i);
Out.String("copied the str into the content starting from the tmp last index one less");Out.Ln;
(*do I need to handle assigning the last element to be 0X in the copy or here? *)

END ReallocAndAppend;


PROCEDURE Append*(arr: dynamicarray; str: ARRAY OF CHAR);
BEGIN
Out.String("entered append"); Out.Ln;
  IF arr.content = NIL THEN
    Out.String("arr content is pointer  nill, trying to realloc"); Out.Ln;
    NEW(arr.content, LEN(str)); (*memory alloc*)
    arr.size := LEN(str); 
    arr.capacity := LEN(str);
    COPY(str, arr.content^);
  ELSE
    Out.String("arr content pointer is not nill, trying to enter realloc and append"); Out.Ln;
    ReallocAndAppend(arr, str);
  END;
  
END Append;


PROCEDURE Init*(arr: dynamicarray; size: LONGINT);
(*initializes with nulls*)
VAR 
i: LONGINT;
BEGIN
Out.String("capacity during initialization: "); Out.Int(arr.capacity, 0); Out.Ln;
Out.String("size during initialization: "); Out.Int(arr.size, 0); Out.Ln;
(*NEW(arr);
what is dereferencing
IF arr.capacity = 0 THEN arr.capacity := size; arr.size := size; END;
IF size <= arr.capacity THEN
  arr.size := size;
  arr.capacity := size;
ELSE 
  Out.String("you cannot have more elements than you have the capacity for"); Out.Ln; HALT(0);
END;*)
NEW(arr.content, size);
arr.size := size; 
arr.capacity := size;
	
i := 0;
REPEAT
arr.content^[i] := 0X;
INC(i);
UNTIL i = size;
Out.String("capacity after initialization: "); Out.Int(arr.capacity, 0); Out.Ln;
Out.String("size after initialization: "); Out.Int(arr.size, 0); Out.Ln;

END Init;

(*first we gotta create then initialize*)
PROCEDURE Create*(): dynamicarray;

VAR 
arr: dynamicarray;

BEGIN
NEW(arr);
arr.content := NIL;
(*
NEW(arr.content, capacity);
arr.capacity := capacity;
*)


arr.size := 0;
arr.capacity := 0;
arr.appender := Append;
RETURN arr;
END Create;




PROCEDURE Resize*(arr: dynamicarray): dynamicarray;
VAR 
  i: LONGINT;
  newarr: dynamicarray;
BEGIN
  NEW(newarr); (*memory allocation*)
  NEW(newarr.content, 2 * arr.capacity); (*data allocation*)
  i := 0; 
  REPEAT 
    newarr.content^[i] := arr.content^[i]; 
  UNTIL i = arr.size;
  newarr.size := arr.size;
  newarr.capacity := 2 * arr.capacity;
  RETURN newarr;
END Resize;




END dynamicarray.

MODULE dynamictest;


IMPORT dynamicarray, Out, Files;

VAR 
arr: dynamicarray.dynamicarray;
i: LONGINT;
r: Files.Rider;
file: Files.File;
BEGIN 

arr := dynamicarray.Create(); (*create with capacity 0*)
(*dynamicarray.Init(arr, 5);*) (*this make the cap and size 5*)
Out.String("in the test module, the array size is: "); Out.Int(arr^.size, 0); Out.Ln;
Out.String("in the test module, the array capacity is: "); Out.Int(arr^.capacity, 0); Out.Ln;
(*REPEAT

(*Out.Char(dynamicarray.Dynamicarraychar(arr)^.content^[i]); Out.Ln;*)
(*Out.Char(arr.content^[i]); Out.Ln;*)

(*Out.Char(arr^.content^[i]); Out.Ln;*)
Out.Char(arr^.content^[i]); Out.Ln;
Out.String("printed."); Out.Ln;
INC(i);
UNTIL i = arr^.capacity;;
*)

(*dynamicarray.Append(arr, "bbbbbbbbbb");*)
arr.appender(arr, "bbbbbbbbbb");
Out.String("10 + 1 is 11"); Out.Ln;
i := 0;
REPEAT
Out.Char(arr^.content^[i]); Out.Ln;
Out.String("printed"); Out.Ln;
INC(i);
UNTIL i = arr^.capacity;

Out.String("the current arr capacity is: "); Out.Int(i, 0); Out.Ln;
dynamicarray.Append(arr, "aaaaa");
Out.String("10 + 5 + 1 is 16"); Out.Ln;
i := 0;
REPEAT
Out.Char(arr^.content^[i]); Out.Ln;
Out.String("printed");Out.Ln;
INC(i);
UNTIL i = arr^.capacity;

Out.String("the current arr capacity is: "); Out.Int(i, 0); Out.Ln;
dynamicarray.Append(arr, "ccc");
i := 0;
REPEAT
Out.Char(arr^.content^[i]); Out.Ln;
Out.String("printed");Out.Ln;
INC(i);
UNTIL i = arr^.capacity;

Out.String("the current arr capacity is: "); Out.Int(i, 0); Out.Ln;

dynamicarray.Append(arr, "ddddd");


i := 0;
REPEAT
Out.Char(arr^.content^[i]); Out.Ln;
Out.String("printed");Out.Ln;
INC(i);
UNTIL i = arr^.capacity;

dynamicarray.Append(arr,"aoethuoenhunoaehuneoathusnaothuensoathunoatehusanotheusnaotheunsatoheunsaothusnaotheusnaotheunoathueanosheunatohuanoetuhnaotheu"); Out.Ln;


i := 0;
REPEAT
Out.Char(arr^.content^[i]); Out.Ln;
Out.String("printed");Out.Ln;
INC(i);
UNTIL i = arr^.capacity;


Out.String("the current arr capacity is: "); Out.Int(i, 0); Out.Ln;
(*
file := Files.New("aaa.md");
i := 0;
Out.String(TYPE(arr^.content^[0]); Out.Ln;



REPEAT
  Files.WriteString(r, arr^.content^);

  INC(i);
UNTIL i = arr^.capacity;
*)

dynamicarray.writetofile(arr, "idontknow.md");
Out.String("written to file seikou"); Out.Ln;


END dynamictest.

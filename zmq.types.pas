unit zmq.types;

{$mode objfpc}{$H+}

interface

type TRandOf = function (Number : Integer): Integer;

type TZMQSendStringFunction = function (Socket : Pointer; const AString : String): integer;

type TZMQDumpProcedure = procedure(Socket : Pointer);

implementation

end.


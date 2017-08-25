{
  fpc-zmq
  Copyright (C) 2017 Carlos Rafael Fernandes Picanço.

  The present file is distributed under the terms of the GNU Lesser General Public License (LGPL v3.0).

  You should have received a copy of the GNU Lesser General Public License
  along with this program. If not, see <http://www.gnu.org/licenses/>.
}
unit zmq.helpers;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, zmq.types;

  // Receive 0MQ string from socket and convert into ShortString
  // Caller must free returned string. Returns NULL if the context
  // is being terminated.
  function RecvShortString(Socket: Pointer) : String;

  // Convert Shortstring to 0MQ string and send to socket
  function SendString(Socket: Pointer;const  AString: String): integer; overload;

  // Sends string as 0MQ string, as multipart non-terminal
  function SendMoreString(Socket : Pointer; const AString : String): integer;

  // Receives all message parts from socket, prints neatly
  procedure DumpStrings(Socket : Pointer);

var
  RandOf : TRandOf; // Provide random number from 0..(num-1)

  // Receive 0MQ string from socket and convert into ShortString
  // Caller must free returned string. Returns NULL if the context
  // is being terminated.
  s_recv : TZMQRecvStringFunction;
  s_send : TZMQSendStringFunction; // Convert Shortstring to 0MQ string and send to socket
  s_sendmore : TZMQSendStringFunction; // Sends string as 0MQ string, as multipart non-terminal
  s_dump : TZMQDumpProcedure; // Receives all message parts from socket, prints neatly

implementation

uses zmq;

function RecvShortString(Socket: Pointer): String;
var
  buffer : array [0..High(ShortString)] of Byte;
  size : integer;
begin
  Result := '';
  size := zmq_recv(Socket, @buffer, High(buffer), 0);
  if size = -1 then exit;
  buffer[size] := $00;
  SetString(Result, PAnsiChar(@buffer), size);
end;

function SendString(Socket: Pointer; const AString: String): integer;
begin
  Result := zmq_send(Socket, @AString[1], Length(AString), 0);
end;

function SendMoreString(Socket: Pointer; const  AString: String): integer;
begin
  Result := zmq_send(Socket, @AString[1], Length(AString), ZMQ_SNDMORE);
end;

procedure DumpStrings(Socket: Pointer);
var
  rc : integer = -1;
  message : zmq_msg_t;

  size : integer = 0;
  data : PChar;

  is_text : Boolean;
  char_nbr : integer;
begin
  rc := zmq_msg_init(message);
  Assert(rc = 0);

  WriteLn('----------------------------------------');
  //  Process all parts of the message

  repeat
    size := zmq_msg_recv(message, Socket, 0);
    Assert(size >= 0);

    //  Dump the message as text or binary
    data := zmq_msg_data(message);
    Assert(data <> nil);
    is_text := True;
    for char_nbr := 0 to size -1 do
      if   (Ord(data[char_nbr]) < 32)
        or (Ord(data[char_nbr]) > 126)
      then is_text := False;

    WriteLn(size);
    for char_nbr := 0 to size -1 do
      if is_text then
        Write(data[char_nbr])
      else
        Write(HexStr(@data[char_nbr]));

    Write(LineEnding);
  until zmq_msg_more(message) = 0;

  rc := zmq_msg_close(message);
  Assert(rc = 0);
end;

initialization
  RandOf := @Random;
  s_recv := @RecvShortString;
  s_send := @SendString;
  s_sendmore := @SendMoreString;
  s_dump := @DumpStrings;

finalization

end.

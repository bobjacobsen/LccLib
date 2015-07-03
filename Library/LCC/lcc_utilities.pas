unit lcc_utilities;

{$IFDEF FPC}
{$mode objfpc}{$H+}
{$ENDIF}

interface

uses
  Classes, SysUtils,
  {$IFDEF MSWINDOWS}
  Windows,
  {$ELSE}
    {$IFDEF FPC}
    LclIntf,
    {$ELSE}
    strutils,
    {$ENDIF}
  {$ENDIF}
  Types, lcc_defines;

  function GetTickCount : DWORD;
  function _Lo(Data: DWORD): Byte;
  function _Hi(Data: DWORD): Byte;
  function _Higher(Data: DWORD): Byte;
  function _Highest(Data: DWORD): Byte;
  function _Highest1(Data: QWord): Byte;
  function _Highest2(Data: QWord): Byte;
  function MTI2String(MTI: Word): string;
  function EqualNodeID(NodeID1: TNodeID; NodeID2: TNodeID; IncludeNullNode: Boolean): Boolean;
  function EqualEventID(EventID1, EventID2: TEventID): Boolean;
  function NullNodeID(ANodeID: TNodeID): Boolean;
  procedure StringToNullArray(AString: LccString; var ANullArray: array of Byte; var iIndex: Integer);
  function NullArrayToString(var ANullArray: array of Byte): LccString;

{$IFDEF FPC}
type
  TCriticalSection = class
  protected
    Lock: TRTLCriticalSection;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Enter;
    procedure Leave;
  end;
{$ENDIF}

type
    { TLccEthernetBaseThread }

  TLccEthernetBaseThread = class(TThread)
  private
    FGridConnect: Boolean;
  public
    property GridConnect: Boolean read FGridConnect write FGridConnect;
  end;

implementation

function GetTickCount : DWORD;
 {On Windows, this is number of milliseconds since Windows was
   started. On non-Windows platforms, LCL returns number of
   milliseconds since Dec. 30, 1899, wrapped by size of DWORD.
   This value can overflow LongInt variable when checks turned on,
   so "wrap" value here so it fits within LongInt.
  Also, since same thing could happen with Windows that has been
   running for at least approx. 25 days, override it too.}
begin
{$IFDEF FPC}
  {$IFDEF MSWINDOWS}
    Result := Windows.GetTickCount mod High(LongInt);
  {$ELSE}
    Result := LclIntf.GetTickCount mod High(LongInt);
  {$ENDIF}
{$ELSE}
  Result := TThread.GetTickCount;
{$ENDIF}
end;

function _Lo(Data: DWORD): Byte;
begin
  Result := Byte(Data) and $000000FF;
end;

function _Hi(Data: DWORD): Byte;
begin
  Result := Byte((Data shr 8) and $000000FF);
end;

function _Higher(Data: DWORD): Byte;
begin
  Result := Byte((Data shr 16) and $000000FF);
end;

function _Highest(Data: DWORD): Byte;
begin
  Result := Byte((Data shr 24) and $000000FF);
end;

function _Highest1(Data: QWord): Byte;
begin
  Result := Byte((Data shr 32) and $00000000000000FF);
end;

function _Highest2(Data: QWord): Byte;
begin
  Result := Byte((Data shr 40) and $00000000000000FF);
end;

function MTI2String(MTI: Word): string;
begin
  case MTI of
  {  MTI_CID0 : Result := 'Check ID 0';
    MTI_CID1 : Result := 'Check ID 1';
    MTI_CID2 : Result := 'Check ID 2';
    MTI_CID3 : Result := 'Check ID 3';
    MTI_CID4 : Result := 'Check ID 4';
    MTI_CID5 : Result := 'Check ID 5';
    MTI_CID6 : Result := 'Check ID 6';

    MTI_RID : Result := 'Reserve ID [RID]';
    MTI_AMD : Result := 'Alias Map Definition [AMD]';
    MTI_AME : Result := 'Alias Map Enquiry [AME]';
    MTI_AMR : Result := 'Alias Map Reset [AMR]'; }

    MTI_INITIALIZATION_COMPLETE : Result := 'Initialization Complete';
    MTI_VERIFY_NODE_ID_NUMBER_DEST : Result := 'Verify Node ID with Destination Address';
    MTI_VERIFY_NODE_ID_NUMBER      : Result := 'Verify Node ID Global';
    MTI_VERIFIED_NODE_ID_NUMBER    : Result := 'Verified Node ID';
    MTI_OPTIONAL_INTERACTION_REJECTED : Result := 'Optional Interaction Rejected';
    MTI_TERMINATE_DUE_TO_ERROR        : Result := 'Terminate Due to Error';

    MTI_PROTOCOL_SUPPORT_INQUIRY  : Result := 'Protocol Support Inquiry';
    MTI_PROTOCOL_SUPPORT_REPLY    : Result := 'Protocol Support Reply';

    MTI_TRACTION_PROXY_PROTOCOL   : Result := 'Protocol Traction Proxy';
    MTI_TRACTION_PROXY_REPLY      : Result := 'Protocol Traction Proxy Reply';

    MTI_CONSUMER_IDENTIFY              : Result := 'Consumer Identify';
    MTI_CONSUMER_IDENTIFY_RANGE        : Result := 'Consumer Identify Range';
    MTI_CONSUMER_IDENTIFIED_UNKNOWN    : Result := 'Consumer Identified Unknown';
    MTI_CONSUMER_IDENTIFIED_SET        : Result := 'Consumer Identified Valid';
    MTI_CONSUMER_IDENTIFIED_CLEAR      : Result := 'Consumer Identified Clear';
    MTI_CONSUMER_IDENTIFIED_RESERVED   : Result := 'Consumer Identified Reserved';
    MTI_PRODUCER_IDENDIFY              : Result := 'Producer Identify';
    MTI_PRODUCER_IDENTIFY_RANGE        : Result := 'Producer Identify Range';
    MTI_PRODUCER_IDENTIFIED_UNKNOWN    : Result := 'Producer Identified Unknown';
    MTI_PRODUCER_IDENTIFIED_SET        : Result := 'Producer Identified Valid';
    MTI_PRODUCER_IDENTIFIED_CLEAR      : Result := 'Producer Identified Clear';
    MTI_PRODUCER_IDENTIFIED_RESERVED   : Result := 'Producer Identified Reserved';
    MTI_EVENTS_IDENTIFY_DEST           : Result := 'Events Identify with Destination Address';
    MTI_EVENTS_IDENTIFY                : Result := 'Events Identify Global';
    MTI_EVENT_LEARN                    : Result := 'Event Learn';
    MTI_PC_EVENT_REPORT                : Result := 'Producer/Consumer Event Report [PCER] ';

    MTI_SIMPLE_NODE_INFO_REQUEST       : Result := 'Simple Node Info Request [SNIP]';
    MTI_SIMPLE_NODE_INFO_REPLY         : Result := 'Simple Node Info Reply [SNIP]';

    MTI_SIMPLE_TRAIN_INFO_REQUEST       : Result := 'Simple Train Node Info Request [STNIP]';
    MTI_SIMPLE_TRAIN_INFO_REPLY         : Result := 'Simple Train Node Info Reply [STNIP]';

    MTI_DATAGRAM                       : Result := 'Datagram';
    MTI_DATAGRAM_OK_REPLY              : begin
                                           Result := 'Datagram Reply OK';
                                  {         if LocalHelper.DataCount > 2 then
                                           begin
                                             if LocalHelper.Data[2] and DATAGRAM_OK_ACK_REPLY_PENDING = DATAGRAM_OK_ACK_REPLY_PENDING then
                                             begin
                                               if LocalHelper.Data[2] and $7F = 0 then
                                                 Result := Result + ' - Reply Is Pending - Maximum wait time = Infinity'
                                               else
                                                 Result := Result + ' - Reply Is Pending - Maximum wait time = ' + IntToStr( Round( Power(2, LocalHelper.Data[2] and $7F))) + ' seconds'
                                             end else
                                               Result := Result + ' - Reply Is Not Pending'
                                           end else
                                             Result := Result + ' - Does not include Extended Flags';   }
                                         end;
    MTI_DATAGRAM_REJECTED_REPLY        : Result := 'Datagram Rejected Reply';

    MTI_TRACTION_PROTOCOL              : Result := 'Traction Protocol';
    MTI_TRACTION_REPLY                 : Result := 'Traction Reply';

    MTI_STREAM_INIT_REQUEST            : Result := 'Stream Request';
    MTI_STREAM_INIT_REPLY              : Result := 'Stream Init Reply';
    MTI_STREAM_SEND                    : Result := 'Stream Send';
    MTI_STREAM_PROCEED                 : Result := 'Stream Proceed';
    MTI_STREAM_COMPLETE                : Result := 'Stream Complete';
   else
    Result := 'Unknown MTI';
  end;
end;

function EqualNodeID(NodeID1: TNodeID; NodeID2: TNodeID; IncludeNullNode: Boolean): Boolean;
begin
  if IncludeNullNode then
    Result := (NodeID1[0] = NodeID2[0]) and (NodeID1[1] = NodeID2[1])
  else
    Result := not NullNodeID(NodeID1) and not NullNodeID(NodeID2) and (NodeID1[0] = NodeID2[0]) and (NodeID1[1] = NodeID2[1])
end;

function EqualEventID(EventID1, EventID2: TEventID): Boolean;
begin
  Result := (EventID1[0] = EventID2[0]) and
            (EventID1[1] = EventID2[1]) and
            (EventID1[2] = EventID2[2]) and
            (EventID1[3] = EventID2[3]) and
            (EventID1[4] = EventID2[4]) and
            (EventID1[5] = EventID2[5]) and
            (EventID1[6] = EventID2[6]) and
            (EventID1[7] = EventID2[7])
end;

function NullNodeID(ANodeID: TNodeID): Boolean;
begin
  Result := (ANodeID[0] = 0) and (ANodeID[1] = 0)
end;

procedure StringToNullArray(AString: LccString; var ANullArray: array of Byte; var iIndex: Integer);
var
  {$IFDEF FPC}
  CharPtr: PAnsiChar;
  {$ELSE}
  CharPtr: PChar;
  {$ENDIF}
  Len, i: Integer;
begin
  {$IFDEF FPC}
  CharPtr := @AString[1];
  {$ELSE}
  CharPtr := @AString[Low(AString)];
  {$ENDIF}
  Len := Length(AString);
  for i := Low(AString) to Len do
  begin
    ANullArray[iIndex] := Ord( CharPtr^);
    Inc(CharPtr);
    Inc(iIndex);
  end;
  ANullArray[iIndex] := 0;
  Inc(iIndex);
end;

function NullArrayToString(var ANullArray: array of Byte): LccString;
var
  i: Integer;
begin
  Result := '';
  i := 0;
  while ANullArray[i] <> 0 do
  begin
    Result := Result + Chr( ANullArray[i]);
    Inc(i);
  end;
end;

{$IFDEF FPC}
{ TCriticalSection }

constructor TCriticalSection.Create;
begin
  System.InitCriticalSection(Lock);
end;

destructor TCriticalSection.Destroy;
begin
  DoneCriticalsection(Lock);
end;

procedure TCriticalSection.Enter;
begin
  System.EnterCriticalsection(Lock);
end;

procedure TCriticalSection.Leave;
begin
  System.LeaveCriticalsection(Lock);
end;
{$ENDIF}

end.



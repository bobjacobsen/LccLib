unit lcc_nodemanager;

{$IFDEF FPC}
{$mode objfpc}{$H+}
{$ENDIF}

{.$DEFINE TRACTION}

interface

uses
  Classes, SysUtils, FileUtil,
  {$IFDEF FPC}
  laz2_DOM, laz2_XMLRead, LResources, ExtCtrls, ComCtrls,
  {$ENDIF}
  {$IFNDEF FPC}
  Types,
  FMX.Types,
  System.Generics.Collections,
  {$ENDIF}
  lcc_utilities, lcc_math_float16, lcc_messages, lcc_app_common_settings,
  lcc_common_classes, lcc_defines, lcc_nodeselector;

const
  ERROR_CONFIGMEM_ADDRESS_SPACE_MISMATCH = $0001;

const
  // These must be IDENTICAL to the values in the CDI file below
  SNIP_VER = 1;
  SNIP_MFG = 'Mustangpeak';
  SNIP_MODEL = 'SW100';
  SNIP_HW_VER = '1.0.0.0';
  SNIP_SW_VER = '1.0.0.0';
  SNIP_USER_VER = 1;
  SNIP_USER_NAME = '';
  SNIP_USER_DESC = '';


const
  MAX_CDI_ARRAY = 766;
  CDI_ARRAY: array[0..MAX_CDI_ARRAY-1] of byte = (
    $3C, $3F, $78, $6D, $6C, $20, $76, $65, $72, $73, $69, $6F, $6E, $3D, $22, $31, $2E, $30, $22, $20, $65, $6E, $63, $6F, $64, $69, $6E, $67, $3D, $22, $75, $74, $66, $2D, $38, $22, $3F, $3E,    // <?xml version="1.0" encoding="utf-8"?>
    $3C, $3F, $78, $6D, $6C, $2D, $73, $74, $79, $6C, $65, $73, $68, $65, $65, $74, $20, $74, $79, $70, $65, $3D, $22, $74, $65, $78, $74, $2F, $78, $73, $6C, $22, $20, $68, $72, $65, $66, $3D, $22, $68, $74, $74, $70, $3A, $2F, $2F, $6F, $70, $65, $6E, $6C, $63, $62, $2E, $6F, $72, $67, $2F, $74, $72, $75, $6E, $6B, $2F, $70, $72, $6F, $74, $6F, $74, $79, $70, $65, $73, $2F, $78, $6D, $6C, $2F, $78, $73, $6C, $74, $2F, $63, $64, $69, $2E, $78, $73, $6C, $22, $3F, $3E,    // <?xml-stylesheet type="text/xsl" href="http://openlcb.org/trunk/prototypes/xml/xslt/cdi.xsl"?>
    $3C, $63, $64, $69, $20, $78, $6D, $6C, $6E, $73, $3A, $78, $73, $69, $3D, $22, $68, $74, $74, $70, $3A, $2F, $2F, $77, $77, $77, $2E, $77, $33, $2E, $6F, $72, $67, $2F, $32, $30, $30, $31, $2F, $58, $4D, $4C, $53, $63, $68, $65, $6D, $61, $2D, $69, $6E, $73, $74, $61, $6E, $63, $65, $22, $20, $78, $73, $69, $3A, $6E, $6F, $4E, $61, $6D, $65, $73, $70, $61, $63, $65, $53, $63, $68, $65, $6D, $61, $4C, $6F, $63, $61, $74, $69, $6F, $6E, $3D, $22, $68, $74, $74, $70, $3A, $2F, $2F, $6F, $70, $65, $6E, $6C, $63, $62, $2E, $6F, $72, $67, $2F, $74, $72, $75, $6E, $6B, $2F, $73, $70, $65, $63, $73, $2F, $73, $63, $68, $65, $6D, $61, $2F, $63, $64, $69, $2E, $78, $73, $64, $22, $3E,    // <cdi xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://openlcb.org/trunk/specs/schema/cdi.xsd">
    $3C, $69, $64, $65, $6E, $74, $69, $66, $69, $63, $61, $74, $69, $6F, $6E, $3E,    // <identification>
    $3C, $6D, $61, $6E, $75, $66, $61, $63, $74, $75, $72, $65, $72, $3E, $4D, $75, $73, $74, $61, $6E, $67, $70, $65, $61, $6B, $3C, $2F, $6D, $61, $6E, $75, $66, $61, $63, $74, $75, $72, $65, $72, $3E,    // <manufacturer>Mustangpeak</manufacturer>
    $3C, $6D, $6F, $64, $65, $6C, $3E, $53, $57, $31, $30, $30, $3C, $2F, $6D, $6F, $64, $65, $6C, $3E,    // <model>SW100</model>
    $3C, $68, $61, $72, $64, $77, $61, $72, $65, $56, $65, $72, $73, $69, $6F, $6E, $3E, $31, $2E, $30, $2E, $30, $2E, $30, $3C, $2F, $68, $61, $72, $64, $77, $61, $72, $65, $56, $65, $72, $73, $69, $6F, $6E, $3E,    // <hardwareVersion>1.0.0.0</hardwareVersion>
    $3C, $73, $6F, $66, $74, $77, $61, $72, $65, $56, $65, $72, $73, $69, $6F, $6E, $3E, $31, $2E, $30, $2E, $30, $2E, $30, $3C, $2F, $73, $6F, $66, $74, $77, $61, $72, $65, $56, $65, $72, $73, $69, $6F, $6E, $3E,    // <softwareVersion>1.0.0.0</softwareVersion>
    $3C, $2F, $69, $64, $65, $6E, $74, $69, $66, $69, $63, $61, $74, $69, $6F, $6E, $3E,    // </identification>
    $3C, $73, $65, $67, $6D, $65, $6E, $74, $20, $6F, $72, $69, $67, $69, $6E, $3D, $22, $31, $22, $20, $73, $70, $61, $63, $65, $3D, $22, $32, $35, $33, $22, $3E,    // <segment origin="1" space="253">
    $3C, $6E, $61, $6D, $65, $3E, $55, $73, $65, $72, $3C, $2F, $6E, $61, $6D, $65, $3E,    // <name>User</name>
    $3C, $64, $65, $73, $63, $72, $69, $70, $74, $69, $6F, $6E, $3E, $55, $73, $65, $72, $20, $64, $65, $66, $69, $6E, $65, $64, $20, $69, $6E, $66, $6F, $72, $6D, $61, $74, $69, $6F, $6E, $3C, $2F, $64, $65, $73, $63, $72, $69, $70, $74, $69, $6F, $6E, $3E,    // <description>User defined information</description>
    $3C, $67, $72, $6F, $75, $70, $3E,    // <group>
    $3C, $6E, $61, $6D, $65, $3E, $55, $73, $65, $72, $20, $44, $61, $74, $61, $3C, $2F, $6E, $61, $6D, $65, $3E,    // <name>User Data</name>
    $3C, $64, $65, $73, $63, $72, $69, $70, $74, $69, $6F, $6E, $3E, $41, $64, $64, $20, $79, $6F, $75, $72, $20, $6F, $77, $6E, $20, $75, $6E, $69, $71, $75, $65, $20, $6E, $6F, $64, $65, $20, $69, $6E, $66, $6F, $20, $68, $65, $72, $65, $3C, $2F, $64, $65, $73, $63, $72, $69, $70, $74, $69, $6F, $6E, $3E,    // <description>Add your own unique node info here</description>
    $3C, $73, $74, $72, $69, $6E, $67, $20, $73, $69, $7A, $65, $3D, $22, $36, $33, $22, $3E,    // <string size="63">
    $3C, $6E, $61, $6D, $65, $3E, $55, $73, $65, $72, $20, $4E, $61, $6D, $65, $3C, $2F, $6E, $61, $6D, $65, $3E,    // <name>User Name</name>
    $3C, $2F, $73, $74, $72, $69, $6E, $67, $3E,    // </string>
    $3C, $73, $74, $72, $69, $6E, $67, $20, $73, $69, $7A, $65, $3D, $22, $36, $34, $22, $3E,    // <string size="64">
    $3C, $6E, $61, $6D, $65, $3E, $55, $73, $65, $72, $20, $44, $65, $73, $63, $72, $69, $70, $74, $69, $6F, $6E, $3C, $2F, $6E, $61, $6D, $65, $3E,    // <name>User Description</name>
    $3C, $2F, $73, $74, $72, $69, $6E, $67, $3E,    // </string>
    $3C, $2F, $67, $72, $6F, $75, $70, $3E,    // </group>
    $3C, $2F, $73, $65, $67, $6D, $65, $6E, $74, $3E,    // </segment>
    $3C, $2F, $63, $64, $69, $3E, $00   // </cdi>
  );



type
  TLccNode = class;
  TLccNodeManager = class;
  {$IFDEF TRACTION}
  TTraction = class;
  {$ENDIF}
  TConfigurationMemory = class;
  TLccOwnedNode = class;
  TLccOwnedNodeClass = class of TLccOwnedNode;
  TLccNetworkTree = class;

  TOnLccNodeMessage = procedure(Sender: TObject; LccSourceNode: TLccNode) of object;
  TOnLccNodeMessageWithDest = procedure(Sender: TObject; LccSourceNode, LccDestNode: TLccNode) of object;
  TOnLccNodeEventIdentified = procedure(Sender: TObject; LccSourceNode: TLccNode; var Event: TEventID; State: TEventState) of object;
  {$IFDEF TRACTION}
  TOnLccNodeTractionProxyReplyAllocate = procedure(Sender: TObject; LccSourceNode, LccDestNode: TLccNode; LegacyTechnology: Byte; TrainID: Word; var TrainNode: TNodeID; TrainAlias: Word) of object;
  TOnLccNodeTractionProxyReplyAttach = procedure(Sender: TObject; LccSourceNode, LccDestNode: TLccNode; ReplyCode: Byte) of object;
  TOnLccNodeMessageResultCode = procedure(Sender: TObject; LccSourceNode, LccDestNode: TLccNode; ResultCode: Byte) of object;
  TOnLccNodeTractionControllerQuery = procedure(Sender: TObject; LccSourceNode, LccDestNode: TLccNode; ActiveControllerNodeID: TNodeID; ActiveControllerAlias: Word) of object;
  TOnLccNodeTractionControllerChangeNotify = procedure(Sender: TObject; LccSourceNode, LccDestNode: TLccNode; NewRequestingNode: TNodeID; NewRequestingNodeAlias: Word; var Allow: Boolean) of object;
  {$ENDIF}
  TOnLccNodeConfigMem = procedure(Sender: TObject; LccSourceNode, LccDestNode: TLccNode) of object;
  TOnLccNodeConfigMemAddressSpace = procedure(Sender: TObject; LccSourceNode, LccDestNode: TLccNode; AddressSpace: Byte) of object;
  TOnLccGetRootNodeClass = procedure(Sender: TObject; var NodeClass: TLccOwnedNodeClass) of object;

  TMessageInFlight = (mif_Snip,
                      mif_Pip,
                      mif_Cdi,
                      mif_Acdi_Mfg,
                      mif_Acdi_User,
                      mif_ConfigMem,
                      mif_ConfigMemOptions);
  TMessageInFlightSet = set of TMessageInFlight;

  { TNodeProtocolBase }

  TNodeProtocolBase = class(TComponent)
  private
    FCreateTime: DWord;
    FErrorCode: Word;
    FNext: TNodeProtocolBase;
    FOwnerManager: TLccNodeManager;
    FValid: Boolean;
    FWorkerMessage: TLccMessage;
    procedure SetOwnerManager(AValue: TLccNodeManager); virtual;
    procedure SetValid(AValue: Boolean); virtual;
  protected
    property CreateTime: DWord read FCreateTime write FCreateTime;
    property OwnerManager: TLccNodeManager read FOwnerManager write SetOwnerManager;
    property WorkerMessage: TLccMessage read FWorkerMessage write FWorkerMessage;
  public
    property ErrorCode: Word read FErrorCode write FErrorCode;
    property Valid: Boolean read FValid write SetValid;
    property Next: TNodeProtocolBase read FNext write FNext;

    constructor Create(AnOwner: TComponent); override;
    destructor Destroy; override;
    function ProcessMessage(LccMessage: TLccMessage): Boolean; virtual; abstract;
  end;

  { TProtocolSupport }

  TProtocolSupport = class(TNodeProtocolBase)
  private
    FACDI: Boolean;
    FCDI: Boolean;
    FDatagram: Boolean;
    FDisplay: Boolean;
    FEventExchange: Boolean;
    {$IFDEF TRACTION}
    FFDI: Boolean;
    {$ENDIF}
    FIdentification: Boolean;
    FMemConfig: Boolean;
    FRemoteButton: Boolean;
    FReservation: Boolean;
    FSimpleNodeInfo: Boolean;
    FStream: Boolean;
    FTeach_Learn: Boolean;
    {$IFDEF TRACTION}
    FTractionControl: Boolean;
    FTractionProxy: Boolean;
    FSimpleTrainNodeInfo: Boolean;
    FFunctionConfiguration: Boolean;
    {$ENDIF}
  protected
    Flags: array of QWord;
    procedure DecodeFlags;
    function EncodeFlags: QWord;
  public
    property Datagram: Boolean read FDatagram write FDatagram;
    {$IFDEF TRACTION}
    property FDI: Boolean read FFDI write FFDI;
    property FunctionConfiguration: Boolean read FFunctionConfiguration write FFunctionConfiguration;
    {$ENDIF}
    property Stream: Boolean read FStream write FStream;
    property MemConfig: Boolean read FMemConfig write FMemConfig;
    property Reservation: Boolean read FReservation write FReservation;
    property EventExchange: Boolean read FEventExchange write FEventExchange;
    property Identification: Boolean read FIdentification write FIdentification;
    property Teach_Learn: Boolean read FTeach_Learn write FTeach_Learn;
    property RemoteButton: Boolean read FRemoteButton write FRemoteButton;
    property ACDI: Boolean read FACDI write FACDI;
    property Display: Boolean read FDisplay write FDisplay;
    property SimpleNodeInfo: Boolean read FSimpleNodeInfo write FSimpleNodeInfo;
    property CDI: Boolean read FCDI write FCDI;
    {$IFDEF TRACTION}
    property TractionControl: Boolean read FTractionControl write FTractionControl;
    property TractionProxy: Boolean read FTractionProxy write FTractionProxy;
    property SimpleTrainNodeInfo: Boolean read FSimpleTrainNodeInfo write FSimpleTrainNodeInfo;
    {$ENDIF}

    function ProcessMessage(LccMessage: TLccMessage): Boolean; override;
  end;

  { TSimpleNodeInfo }

  TSimpleNodeInfo = class(TNodeProtocolBase)
  private
    FHardwareVersion: string;
    FManufacturer: string;
    FModel: string;
    FSoftwareVersion: string;
    FPackedInfo: TSimpleNodeInfoPacked;
    FUserDescription: string;
    FUserName: string;
    FUserVersion: Word;
    FVersion: Word;

    function GetPackedFormat: TSimpleNodeInfoPacked;
    function GetUserDescription: string;
    function GetUserName: string;
  public
    property Version: Word read FVersion write FVersion;
    property Manufacturer: string read FManufacturer write FManufacturer;
    property Model: string read FModel write FModel;
    property HardwareVersion: string read FHardwareVersion write FHardwareVersion;
    property SoftwareVersion: string read FSoftwareVersion write FSoftwareVersion;
    property UserVersion: Word read FUserVersion write FUserVersion;
    property UserName: string read GetUserName write FUserName;
    property UserDescription: string read GetUserDescription write FUserDescription;

    property PackedFormat: TSimpleNodeInfoPacked read GetPackedFormat;

    function LoadFromXml(CdiFilePath: string): Boolean;
    function ProcessMessage(LccMessage: TLccMessage): Boolean; override;
  end;

  {$IFDEF TRACTION}
  { TSimpleTrainNodeInfo }

  TSimpleTrainNodeInfo = class(TNodeProtocolBase)
  private
    FManufacturer: string;
    FOwner: string;
    FRoadname: string;
    FRoadNumber: string;
    FTrainClass: string;
    FTrainName: string;
    FVersion: Word;
  public
    property Version: Word read FVersion;
    property Roadname: string read FRoadname;
    property TrainClass: string read FTrainClass;
    property RoadNumber: string read FRoadNumber;
    property TrainName: string read FTrainName;
    property Manufacturer: string read FManufacturer;
    property Owner: string read FOwner;

    function ProcessMessage(LccMessage: TLccMessage; Traction: TTraction): Boolean; reintroduce; virtual;
  end;
  {$ENDIF}

  { TLccEvent }

  TLccEvent = class
  private
    FID: TEventID;
    FState: TEventState;
  public
    property ID: TEventID read FID write FID;
    property State: TEventState read FState write FState;
  end;

  { TLccEvents }

  TLccEvents = class(TNodeProtocolBase)
  private
    {$IFDEF FPC}
    FEventList: TList;
    {$ELSE}
    FEventList: TObjectList<TLccEvent>;
    {$ENDIF}
    function GetCount: Integer;
    function GetEvent(Index: Integer): TLccEvent;
    function GetEventIDAsStr(Index: Integer): string;
  protected
    {$IFDEF FPC}
      property EventList: TList read FEventList write FEventList;
    {$ELSE}
      property EventList: TObjectList<TLccEvent> read FEventList write FEventList;
    {$ENDIF}
  public
    constructor Create(AnOwner: TComponent); override;
    destructor Destroy; override;

    procedure Add(Event: TEventID; State: TEventState);
    procedure Clear;
    function Supports(Event: TEventID): TLccEvent;
    function ProcessMessage(LccMessage: TLccMessage): Boolean; override;
    property Count: Integer read GetCount;
    property Event[Index: Integer]: TLccEvent read GetEvent; default;
    property EventIDAsStr[Index: Integer]: string read GetEventIDAsStr;
  end;

  { TStreamBasedProtocol }

  TStreamBasedProtocol = class(TNodeProtocolBase)
  private
    FInProcessAddress: DWord;
    FStream: TMemoryStream;
    FAddressSpace: Byte;
  protected
    procedure SetValid(AValue: Boolean); override;
    procedure DoLoadComplete(LccMessage: TLccMessage); virtual;

    property InProcessAddress: DWord read FInProcessAddress write FInProcessAddress;
    property AddressSpace: Byte read FAddressSpace write FAddressSpace;
  public
    property AStream: TMemoryStream read FStream write FStream;

    constructor Create(AnOwner: TComponent; AnAddressSpace: Byte); reintroduce; virtual;
    destructor Destroy; override;
    procedure LoadReply(LccMessage: TLccMessage; OutMessage: TLccMessage); virtual;
    procedure WriteRequest(LccMessage: TLccMessage); virtual;
    function ProcessMessage(LccMessage: TLccMessage): Boolean; override;
  end;

  {$IFDEF TRACTION}
  { TFDI }

  TFDI = class(TStreamBasedProtocol)
  protected
    procedure DoLoadComplete(LccMessage: TLccMessage); override;
  end;
  {$ENDIF}

  {$IFDEF TRACTION}
  { TFunctionConfiguration }

  TFunctionConfiguration = class(TNodeProtocolBase)
  private
    FFunctionStatesArray: TFunctionStatesArray;
    function GetFunctionStates(iIndex: Integer): Boolean;
  protected
    property FunctionStatesArray: TFunctionStatesArray read FFunctionStatesArray write FFunctionStatesArray;
  public
    property FunctionStates[iIndex: Integer]: Boolean read GetFunctionStates;
    function ProcessMessage(LccMessage: TLccMessage): Boolean; override;
  end;
  {$ENDIF}

  { TCDI }

  TCDI = class(TStreamBasedProtocol)
  protected
    procedure DoLoadComplete(LccMessage: TLccMessage); override;
  public
    function LoadFromXml(CdiFilePath: string): Boolean;
  end;

  { TACDIMfg }

  TACDIMfg = class(TStreamBasedProtocol)
  public
    procedure LoadReply(LccMessage: TLccMessage; OutMessage: TLccMessage); virtual;
  end;

  { TACDIUser }

  TACDIUser = class(TACDIMfg)
  public
    procedure LoadReply(LccMessage: TLccMessage; OutMessage: TLccMessage); override;
    procedure WriteRequest(LccMessage: TLccMessage); override;
  end;

  { TConfiguration }

  TConfiguration = class(TStreamBasedProtocol)
  private
    FAutoSaveOnWrite: Boolean;
    FFilePath: string;
  public
    property AutoSaveOnWrite: Boolean read FAutoSaveOnWrite write FAutoSaveOnWrite;
    property FilePath: string read FFilePath write FFilePath;

    constructor Create(AnOwner: TComponent; AnAddressSpace: Byte); override;
    procedure WriteRequest(LccMessage: TLccMessage); override;
    function ReadAsString(Address: DWord): string;
    procedure LoadFromFile;
  end;


  { TConfigurationMemory }

  TConfigurationMemory = class(TNodeProtocolBase)
  private
    FAddress: DWord;
    FAddressSpace: Byte;
    FDataCount: Integer;
    FDataRaw: TDatagramArray;
    FDataType: TLccConfigDataType;
    FDataTypeBit: Byte;
    FDataTypeEvent: TEventID;
    FDataTypeInteger: Integer;
    FDataTypeString: string;
    FInProcessAddress: DWord;
    function GetDataRawIndexer(iIndex: Word): Byte;

    procedure SetDataRawIndexer(iIndex: Word; const Value: Byte);
  protected
    property InProcessAddress: DWord read FInProcessAddress write FInProcessAddress;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property Address: DWord read FAddress write FAddress;
    property AddressSpace: Byte read FAddressSpace write FAddressSpace;
    property DataCount: Integer read FDataCount write FDataCount;
    property DataRaw: TDatagramArray read FDataRaw write FDataRaw;
    property DataRawIndexer[iIndex: Word]: Byte read GetDataRawIndexer write SetDataRawIndexer;
    property DataType: TLccConfigDataType read FDataType write FDataType;
    property DataTypeInteger: Integer read FDataTypeInteger;
    property DataTypeEvent: TEventID read FDataTypeEvent;
    property DataTypeBit: Byte read FDataTypeBit;
    property DataTypeString: string read FDataTypeString;
    procedure Initialize(AnAddress: DWord; AnAddressSpace: Byte; DataSize: Integer; ADataType: TLccConfigDataType);
    function ProcessMessage(LccMessage: TLccMessage): Boolean; override;
  end;

  { TConfigMemAddressSpaceInfoObject }

  TConfigMemAddressSpaceInfoObject = class
  private
    FHighAddress: DWord;
    FIsReadOnly: Boolean;
    FImpliedZeroLowAddress: Boolean;
    FLowAddress: DWord;
    FIsPresent: Boolean;
    FAddressSpace: Byte;
  public
    property AddressSpace: Byte read FAddressSpace;
    property IsPresent: Boolean read FIsPresent;
    property IsReadOnly: Boolean read FIsReadOnly;
    property ImpliedZeroLowAddress: Boolean read FImpliedZeroLowAddress;
    property LowAddress: DWord read FLowAddress;
    property HighAddress: DWord read FHighAddress;
  end;

  { TConfigMemAddressSpaceInfo }

  TConfigMemAddressSpaceInfo = class(TNodeProtocolBase)
  private
    FList: TList;
    function GetAddressSpace(Index: Integer): TConfigMemAddressSpaceInfoObject;
    function GetCount: Integer;
  protected
    property List: TList read FList write FList;
  public
    property AddressSpace[Index: Integer]: TConfigMemAddressSpaceInfoObject read GetAddressSpace; default;
    property Count: Integer read GetCount;

    constructor Create(AnOwner: TComponent); override;
    destructor Destroy; override;
    procedure Add(_Space: Byte; _IsPresent, _IsReadOnly, _ImpliedZeroLowAddress: Boolean; _LowAddress, _HighAddress: DWord);
    procedure Clear;
    function FindByAddressSpace(Space: Byte): TConfigMemAddressSpaceInfoObject;
    procedure LoadReply(LccMessage: TLccMessage; OutMessage: TLccMessage);
    function ProcessMessage(LccMessage: TLccMessage): Boolean; override;
  end;

  {$IFDEF TRACTION}
  { TTraction }

  TTraction = class(TNodeProtocolBase)
  private
    FLegacySpeedSteps: Byte;
    FLegacyTechnology: Byte;
    FLegacyTrainID: Word;
    FLinkedNode: TLccNode;                 // depends on the Node: Throttle Node = Linked Train Node, Train Node = Linked Throttle Node
    FScratchNode: TLccNode;
    FSpeed: THalfFloat;
    FSpeedActual: THalfFloat;
    FSpeedCommanded: THalfFloat;
    procedure SetFunctions(Index: DWord; AValue: Word);
    function GetFunctions(Index: DWord): Word;
  protected
    FunctionArray: array of Word;
    procedure GrowArray(NewSize: DWord);
  public
    property Speed: THalfFloat read FSpeed;
    property SpeedActual: THalfFloat read FSpeedActual;
    property SpeedCommanded: THalfFloat read FSpeedCommanded;
    property Functions[Index: DWord]: Word read GetFunctions;
    property LinkedNode: TLccNode read FLinkedNode write FLinkedNode;
    property LegacyTechnology: Byte read FLegacyTechnology write FLegacyTechnology;
    property LegacyTrainID: Word read FLegacyTrainID write FLegacyTrainID;
    property LegacySpeedSteps: Byte read FLegacySpeedSteps write FLegacySpeedSteps;
    property ScratchNode: TLccNode read FScratchNode write FScratchNode;

    function IsLinked: Boolean;
    function ProcessMessage(LccMessage: TLccMessage): Boolean; override;
  end;
  {$ENDIF}

  { TConfigurationMemOptions }

  TConfigurationMemOptions = class(TNodeProtocolBase)
  private
    FHighSpace: Byte;
    FLowSpace: Byte;
    FSupportACDIMfgRead: Boolean;
    FSupportACDIUserRead: Boolean;
    FSupportACDIUserWrite: Boolean;
    FUnAlignedReads: Boolean;
    FUnAlignedWrites: Boolean;
    FWriteArbitraryBytes: Boolean;
    FWriteLenFourBytes: Boolean;
    FWriteLenOneByte: Boolean;
    FWriteLenSixyFourBytes: Boolean;
    FWriteLenTwoBytes: Boolean;
    FWriteStream: Boolean;
    FWriteUnderMask: Boolean;
  public
    property WriteUnderMask: Boolean read FWriteUnderMask write FWriteUnderMask;
    property UnAlignedReads: Boolean read FUnAlignedReads write FUnAlignedReads;
    property UnAlignedWrites: Boolean read FUnAlignedWrites write FUnAlignedWrites;
    property SupportACDIMfgRead: Boolean read FSupportACDIMfgRead write FSupportACDIMfgRead;
    property SupportACDIUserRead: Boolean read FSupportACDIUserRead write FSupportACDIUserRead;
    property SupportACDIUserWrite: Boolean read FSupportACDIUserWrite write FSupportACDIUserWrite;
    property WriteLenOneByte: Boolean read FWriteLenOneByte write FWriteLenOneByte;
    property WriteLenTwoBytes: Boolean read FWriteLenTwoBytes write FWriteLenTwoBytes;
    property WriteLenFourBytes: Boolean read FWriteLenFourBytes write FWriteLenFourBytes;
    property WriteLenSixyFourBytes: Boolean read FWriteLenSixyFourBytes write FWriteLenSixyFourBytes;
    property WriteArbitraryBytes: Boolean read FWriteArbitraryBytes write FWriteArbitraryBytes;
    property WriteStream: Boolean read FWriteStream write FWriteStream;
    property HighSpace: Byte read FHighSpace write FHighSpace;
    property LowSpace: Byte read FLowSpace write FLowSpace;

    function ProcessMessage(LccMessage: TLccMessage): Boolean; override;
    procedure LoadReply(LccMessage: TLccMessage);
  end;

  { TLccNode }

  TLccNode = class(TNodeProtocolBase)
  private
    FAliasID: Word;
    FCDI: TCDI;
    FConfigurationMem: TConfigurationMemory;
    FConfigMemOptions: TConfigurationMemOptions;
    FEventsConsumed: TLccEvents;
    FEventsProduced: TLccEvents;
    {$IFDEF TRACTION}
    FFDI: TFDI;
    FFunctionConfiguration: TFunctionConfiguration;
    {$ENDIF}
    FiStartupSequence: Word;
    FLccGuiNode: TLccGuiNode;
    FNodeID: TNodeID;
    FProtocolSupport: TProtocolSupport;
    FSimpleNodeInfo: TSimpleNodeInfo;
    {$IFDEF TRACTION}
    FSimpleTrainNodeInfo: TSimpleTrainNodeInfo;
    FTraction: TTraction;
    {$ENDIF}
    FConfigMemAddressSpaceInfo: TConfigMemAddressSpaceInfo;
    FUserMsgInFlight: TMessageInFlightSet;
    function GetAliasIDStr: string;
    function GetNodeIDStr: string;
    procedure SetOwnerManager(AValue: TLccNodeManager); override;
  protected

    function ExtractAddressSpace(LccMessage: TLccMessage): Byte;
    procedure SendAckReply(LccMessage: TLccMessage);
  public
    property AliasID: Word read FAliasID;
    property AliasIDStr: string read GetAliasIDStr;
    property CDI: TCDI read FCDI write FCDI;
    property ConfigurationMem: TConfigurationMemory read FConfigurationMem write FConfigurationMem;
    property ConfigMemOptions: TConfigurationMemOptions read FConfigMemOptions write FConfigMemOptions;
    property ConfigMemAddressSpaceInfo: TConfigMemAddressSpaceInfo read FConfigMemAddressSpaceInfo write FConfigMemAddressSpaceInfo;
    property EventsConsumed: TLccEvents read FEventsConsumed write FEventsConsumed;
    property EventsProduced: TLccEvents read FEventsProduced write FEventsProduced;
    {$IFDEF TRACTION}
    property FDI: TFDI read FFDI write FFDI;
    property FunctionConfiguration: TFunctionConfiguration read FFunctionConfiguration write FFunctionConfiguration;
    {$ENDIF}
    property LccGuiNode: TLccGuiNode read FLccGuiNode write FLccGuiNode;
    property NodeID: TNodeID read FNodeID;
    property NodeIDStr: string read GetNodeIDStr;
    property ProtocolSupport: TProtocolSupport read FProtocolSupport;
    property iStartupSequence: Word read FiStartupSequence write FiStartupSequence;
    property SimpleNodeInfo: TSimpleNodeInfo read FSimpleNodeInfo;
    {$IFDEF TRACTION}
    property SimpleTrainNodeInfo: TSimpleTrainNodeInfo read FSimpleTrainNodeInfo;
    property Traction: TTraction read FTraction write FTraction;
    {$ENDIF}
    property UserMsgInFlight: TMessageInFlightSet read FUserMsgInFlight write FUserMsgInFlight;

    constructor Create(AnOwner: TComponent); override;
    destructor Destroy; override;
    function IsNode(LccMessage: TLccMessage; TestType: TIsNodeTestType): Boolean;
    function ProcessMessage(LccMessage: TLccMessage): Boolean; override;
  end;

  { TLccOwnedNode }

  TLccOwnedNode = class(TLccNode)
  private
    FACDIMfg: TACDIMfg;
    FACDIUser: TACDIUser;
    FConfiguration: TConfiguration;
    FDuplicateAliasDetected: Boolean;
    FInitialized: Boolean;
    FLogInAliasID: Word;
    FLoginTimer: TTimer;
    FPermitted: Boolean;
    FSeedNodeID: TNodeID;
  protected
    property DuplicateAliasDetected: Boolean read FDuplicateAliasDetected write FDuplicateAliasDetected;
    property LogInAliasID: Word read FLogInAliasID write FLogInAliasID;
    property LoginTimer: TTimer read FLoginTimer write FLoginTimer;
    property SeedNodeID: TNodeID read FSeedNodeID write FSeedNodeID;

    function CreateAliasID(var Seed: TNodeID; Regenerate: Boolean): Word;
    function GenerateID_Alias_From_Seed(var Seed: TNodeID): Word;
    procedure GenerateNewNodeID;
    procedure OnLoginTimer(Sender: TObject);
    procedure PsudoRandomNumberGeneratorOnSeed(var Seed: TNodeID);
    procedure SendAliasLoginRequest;
    procedure SendAliasLogin;
    procedure SendAMR;
    procedure SendEvents;
    procedure SendConsumedEvents;
    procedure SendProducedEvents;
  public
    property ACDIMfg: TACDIMfg read FACDIMfg write FACDIMfg;
    property ACDIUser: TACDIUser read FACDIUser write FACDIUser;
    property Configuration: TConfiguration read FConfiguration write FConfiguration;
    property Initialized: Boolean read FInitialized;
    property Permitted: Boolean read FPermitted;

    constructor Create(AnOwner: TComponent); override;
    destructor Destroy; override;
    procedure Login(NewNodeID, RegenerateAliasSeed: Boolean);

    function ProcessMessage(LccMessage: TLccMessage): Boolean; override;
  end;

  { TLccDefaultRootNode }

  TLccDefaultRootNode = class(TLccOwnedNode)
  public
   constructor Create(AnOwner: TComponent); override;
  end;


  { TLccNodeManager }

  TLccNodeManager = class(TComponent)
  private
    FAutoInterrogateDiscoveredNodes: Boolean;
    FCAN: Boolean;
    FCdiParser: TLccCdiParserBase;
    FEnabled: Boolean;
    FHardwareConnection: TLccHardwareConnectionManager;
    FLccSettings: TLccSettings;
    FNodeList: TList;
    FOnAliasIDChanged: TOnLccNodeMessage;
    FOnLccNodeConfigMemAddressSpaceInfoReply: TOnLccNodeConfigMemAddressSpace;
    FOnLccNodeConfigMemOptionsReply: TOnLccNodeConfigMem;
    FOnNodeIDChanged: TOnLccNodeMessage;
    FOnLccGetRootNodeClass: TOnLccGetRootNodeClass;
    FOnLccNodeCDI: TOnLccNodeMessageWithDest;
    FOnLccNodeConfigMemReadReply: TOnLccNodeConfigMem;
    FOnLccNodeConfigMemWriteReply: TOnLccNodeConfigMem;
    FOnLccNodeConsumerIdentified: TOnLccNodeEventIdentified;
    FOnLccNodeCreate: TOnLccNodeMessage;
    FOnLccNodeDatagramReply: TOnLccNodeMessageWithDest;
    FOnLccNodeDestroy: TOnLccNodeMessage;
    {$IFDEF TRACTION}
    FOnLccNodeFDI: TOnLccNodeMessageWithDest;
    FOnLccNodeFunctionConfiguration: TOnLccNodeMessageWithDest;
    {$ENDIF}
    FOnLccNodeInitializationComplete: TOnLccNodeMessage;
    FOnLccNodeOptionalInteractionRejected: TOnLccNodeMessageWithDest;
    FOnLccNodeProducerIdentified: TOnLccNodeEventIdentified;
    FOnLccNodeProtocolIdentifyReply: TOnLccNodeMessageWithDest;
    FOnLccNodeRemoteButtonReply: TOnLccNodeMessageWithDest;
    FOnLccNodeSimpleNodeIdentReply: TOnLccNodeMessageWithDest;
    {$IFDEF TRACTION}
    FOnLccNodeSimpleTrainNodeIdentReply: TOnLccNodeMessageWithDest;
    FOnLccNodeTractionControllerChangeNotify: TOnLccNodeTractionControllerChangeNotify;
    FOnLccNodeTractionProxyReplyAllocate: TOnLccNodeTractionProxyReplyAllocate;
    FOnLccNodeTractionProxyReplyAttach: TOnLccNodeTractionProxyReplyAttach;
    FOnLccNodeTractionProxyReplyManage: TOnLccNodeMessageResultCode;
    FOnLccNodeTractionReplyControllerAssign: TOnLccNodeMessageResultCode;
    FOnLccNodeTractionReplyControllerChangeNotify: TOnLccNodeMessageResultCode;
    FOnLccNodeTractionReplyControllerQuery: TOnLccNodeTractionControllerQuery;
    FOnLccNodeTractionReplyManage: TOnLccNodeMessageResultCode;
    FOnLccNodeTractionReplyQueryFunction: TOnLccNodeMessageWithDest;
    FOnLccNodeTractionReplyQuerySpeed: TOnLccNodeMessageWithDest;
    {$ENDIF}
    FOnLccNodeVerifiedNodeID: TOnLccNodeMessage;
    FOnRequestMessageSend: TOnMessageEvent;
    FOwnedNodeList: TList;
    FRootNode: TLccOwnedNode;
    FTLccNetworkTree: TLccNetworkTree;
    FUserMessage: TLccMessage;
    FWorkerMessage: TLccMessage;
    FAutoSendVerifyNodesOnStart: Boolean;
    function GetNodes(Index: Integer): TLccNode;
    function GetOwnedNodes(Index: Integer): TLccOwnedNode;
    function GetRootNodeAlias: Word;
    function GetRootNodeID: TNodeID;
    procedure SetCAN(AValue: Boolean);
    procedure SetEnabled(AValue: Boolean);
    procedure SetNodes(Index: Integer; AValue: TLccNode);
    procedure SetOwnedNodes(Index: Integer; AValue: TLccOwnedNode);
  protected
    property NodeList: TList read FNodeList write FNodeList;
    property OwnedNodeList: TList read FOwnedNodeList write FOwnedNodeList;

    procedure DoAliasIDChanged(LccNode: TLccNode); virtual;
    procedure DoCDI(SourceLccNode, DestLccNode: TLccNode); virtual;
    procedure DoConfigMemAddressSpaceInfoReply(SourceLccNode, DestLccNode: TLccNode; AddressSpace: Byte); virtual;
    procedure DoConfigMemOptionsReply(SourceLccNode, DestLccNode: TLccNode); virtual;
    procedure DoConfigMemReadReply(SourceLccNode, DestLccNode: TLccNode); virtual;
    procedure DoConfigMemWriteReply(SourceLccNode, DestLccNode: TLccNode); virtual;
    procedure DoCreateLccNode(SourceLccNode: TLccNode); virtual;
    procedure DoConsumerIdentified(SourceLccNode: TLccNode; var Event: TEventID; State: TEventState); virtual;
    procedure DoDatagramReply(SourceLccNode, DestLccNode: TLccNode); virtual;
    procedure DoDestroyLccNode(LccNode: TLccNode); virtual;
    {$IFDEF TRACTION}
    procedure DoFDI(SourceLccNode, DestLccNode: TLccNode); virtual;
    procedure DoFunctionConfiguration(SourceLccNode, DestLccNode: TLccNode); virtual;
    {$ENDIF}
    procedure DoGetRootNodeClass(var RootNodeClass: TLccOwnedNodeClass); virtual;
    procedure DoInitializationComplete(SourceLccNode: TLccNode); virtual;
    procedure DoNodeIDChanged(LccNode: TLccNode); virtual;
    procedure DoOptionalInteractionRejected(SourceLccNode, DestLccNode: TLccNode); virtual;
    procedure DoProducerIdentified(SourceLccNode: TLccNode; var Event: TEventID; State: TEventState); virtual;
    procedure DoProtocolIdentifyReply(SourceLccNode, DestLccNode: TLccNode); virtual;
    procedure DoRemoteButtonReply(SourceLccNode, DestLccNode: TLccNode); virtual;
    procedure DoRequestMessageSend(Message: TLccMessage); virtual;
    procedure DoSimpleNodeIdentReply(SourceLccNode, DestLccNode: TLccNode); virtual;
    {$IFDEF TRACTION}
    procedure DoSimpleTrainNodeIdentReply(SourceLccNode, DestLccNode: TLccNode); virtual;
    procedure DoTractionControllerChangeNotify(SourceLccNode, DestLccNode: TLccNode; NewRequestingNode: TNodeID; NewRequestingNodeAlias: Word; var Allow: Boolean); virtual;
    procedure DoTractionProxyReplyAllocate(SourceLccNode, DestLccNode: TLccNode; LegacyTechnology: Byte; TrainID: Word; var TrainNode: TNodeID; TrainAlias: Word); virtual;
    procedure DoTractionProxyReplyAttach(SourceLccNode, DestLccNode: TLccNode; ReplyCode: Byte); virtual;
    procedure DoTractionProxyReplyManage(SourceLccNode, DestLccNode: TLccNode; ResultCode: Byte); virtual;
    procedure DoTractionReplyQuerySpeed(SourceLccNode, DestLccNode: TLccNode); virtual;
    procedure DoTractionReplyQueryFunction(SourceLccNode, DestLccNode: TLccNode); virtual;
    procedure DoTractionReplyControllerAssign(SourceLccNode, DestLccNode: TLccNode; ResultCode: Byte); virtual;
    procedure DoTractionReplyControllerQuery(SourceLccNode, DestLccNode: TLccNode; ActiveControllerNodeID: TNodeID; ActiveControllerAlias: Word); virtual;
    procedure DoTractionReplyControllerChangeNotify(SourceLccNode, DestLccNode: TLccNode; ResultCode: Byte); virtual;
    procedure DoTractionReplyManage(SourceLccNode, DestLccNode: TLccNode; ResultCode: Byte); virtual;
    {$ENDIF}
    procedure DoVerifiedNodeID(SourceLccNode: TLccNode); virtual;
    function FindSourceNode(LccMessage: TLccMessage; IncludeRoot: Boolean): TLccNode;
    function FindDestNode(LccMessage: TLccMessage; IncludeRoot: Boolean): TLccNode;
    function FindOwnedDestNode(LccMessage: TLccMessage): TLccOwnedNode;
    function FindOwnedSourceNode(LccMessage: TLccMessage): TLccOwnedNode;
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;

    property WorkerMessage: TLccMessage read FWorkerMessage write FWorkerMessage;
  public
    property Nodes[Index: Integer]: TLccNode read GetNodes write SetNodes;
    property OwnedNodes[Index: Integer]: TLccOwnedNode read GetOwnedNodes write SetOwnedNodes;
    property RootNode: TLccOwnedNode read FRootNode write FRootNode;
    property RootNodeID: TNodeID read GetRootNodeID;
    property RootNodeAlias: Word read GetRootNodeAlias;
    property UserMessage: TLccMessage read FUserMessage;

    constructor Create(AnOwner: TComponent); override;
    destructor Destroy; override;

    procedure Clear;
    procedure ClearOwned;
    function CreateNodeBySourceMessage(LccMessage: TLccMessage): TLccNode;
    function CreateNodeByDestMessage(LccMessage: TLccMessage): TLccNode;
    function CreateOwnedNode: TLccOwnedNode;
    function EqualEventID(var Event1, Event2: TEventID): Boolean;
    function FindByGuiNode(GuiNode: TLccGuiNode): TLccNode;
    function FindNode(ANodeID: TNodeID; ANodeAlias: Word): TLccNode;
    function IsManagerNode(LccMessage: TLccMessage; TestType: TIsNodeTestType): Boolean;
    procedure NodeIDStringToNodeID(ANodeIDStr: string; var ANodeID: TNodeID);
    function NodeIDToNodeIDStr(ANodeID: TNodeID): string;
    function ProcessMessage(LccMessage: TLccMessage): Boolean;
    procedure SendLccMessage(LccMessage: TLccMessage);

  published
    property AutoInterrogateDiscoveredNodes: Boolean read FAutoInterrogateDiscoveredNodes write FAutoInterrogateDiscoveredNodes;
    property AutoSendVerifyNodesOnStart: Boolean read FAutoSendVerifyNodesOnStart write FAutoSendVerifyNodesOnStart;
    property Enabled: Boolean read FEnabled write SetEnabled;
    property CAN: Boolean read FCAN write SetCAN;
    property CdiParser: TLccCdiParserBase read FCdiParser write FCdiParser;
    property HardwareConnection: TLccHardwareConnectionManager read FHardwareConnection write FHardwareConnection;
    property LccSettings: TLccSettings read FLccSettings write FLccSettings;
    property NetworkTree: TLccNetworkTree read FTLccNetworkTree write FTLccNetworkTree;
    property OnAliasIDChanged: TOnLccNodeMessage read FOnAliasIDChanged write FOnAliasIDChanged;
    property OnLccGetRootNodeClass: TOnLccGetRootNodeClass read FOnLccGetRootNodeClass write FOnLccGetRootNodeClass;
    property OnLccNodeCDI: TOnLccNodeMessageWithDest read FOnLccNodeCDI write FOnLccNodeCDI;
    property OnLccNodeConfigMemAddressSpaceInfoReply: TOnLccNodeConfigMemAddressSpace read FOnLccNodeConfigMemAddressSpaceInfoReply write FOnLccNodeConfigMemAddressSpaceInfoReply;
    property OnLccNodeConfigMemOptionsReply: TOnLccNodeConfigMem read FOnLccNodeConfigMemOptionsReply write FOnLccNodeConfigMemOptionsReply;
    property OnLccNodeConfigMemReadReply: TOnLccNodeConfigMem read FOnLccNodeConfigMemReadReply write FOnLccNodeConfigMemReadReply;
    property OnLccNodeConfigMemWriteReply: TOnLccNodeConfigMem read FOnLccNodeConfigMemWriteReply write FOnLccNodeConfigMemWriteReply;
    property OnLccNodeConsumerIdentified: TOnLccNodeEventIdentified read FOnLccNodeConsumerIdentified write FOnLccNodeConsumerIdentified;
    property OnLccNodeCreate: TOnLccNodeMessage read FOnLccNodeCreate write FOnLccNodeCreate;
    property OnLccNodeDatagramReply: TOnLccNodeMessageWithDest read FOnLccNodeDatagramReply write FOnLccNodeDatagramReply;
    property OnLccNodeDestroy: TOnLccNodeMessage read FOnLccNodeDestroy write FOnLccNodeDestroy;
    {$IFDEF TRACTION}
    property OnLccNodeFDI: TOnLccNodeMessageWithDest read FOnLccNodeFDI write FOnLccNodeFDI;
    property OnLccNodeFunctionConfiguration: TOnLccNodeMessageWithDest read FOnLccNodeFunctionConfiguration write FOnLccNodeFunctionConfiguration;
    {$ENDIF}
    property OnNodeIDChanged: TOnLccNodeMessage read FOnNodeIDChanged write FOnNodeIDChanged;
    property OnLccNodeInitializationComplete: TOnLccNodeMessage read FOnLccNodeInitializationComplete write FOnLccNodeInitializationComplete;
    property OnLccNodeOptionalInteractionRejected: TOnLccNodeMessageWithDest read FOnLccNodeOptionalInteractionRejected write FOnLccNodeOptionalInteractionRejected;
    property OnLccNodeProducerIdentified: TOnLccNodeEventIdentified read FOnLccNodeProducerIdentified write FOnLccNodeProducerIdentified;
    property OnLccNodeProtocolIdentifyReply: TOnLccNodeMessageWithDest read FOnLccNodeProtocolIdentifyReply write FOnLccNodeProtocolIdentifyReply;
    property OnLccNodeRemoteButtonReply: TOnLccNodeMessageWithDest read FOnLccNodeRemoteButtonReply write FOnLccNodeRemoteButtonReply;
    property OnLccNodeSimpleNodeIdentReply: TOnLccNodeMessageWithDest read FOnLccNodeSimpleNodeIdentReply write FOnLccNodeSimpleNodeIdentReply;
    {$IFDEF TRACTION}
    property OnLccNodeSimpleTrainNodeIdentReply: TOnLccNodeMessageWithDest read FOnLccNodeSimpleTrainNodeIdentReply write FOnLccNodeSimpleTrainNodeIdentReply;
    property OnLccNodeTractionControllerChangeNotify: TOnLccNodeTractionControllerChangeNotify read FOnLccNodeTractionControllerChangeNotify write FOnLccNodeTractionControllerChangeNotify;
    property OnLccNodeTractionReplyQuerySpeed: TOnLccNodeMessageWithDest read FOnLccNodeTractionReplyQuerySpeed write FOnLccNodeTractionReplyQuerySpeed;
    property OnLccNodeTractionReplyQueryFunction: TOnLccNodeMessageWithDest read FOnLccNodeTractionReplyQueryFunction write FOnLccNodeTractionReplyQueryFunction;
    property OnLccNodeTractionReplyControllerAssign: TOnLccNodeMessageResultCode read FOnLccNodeTractionReplyControllerAssign write FOnLccNodeTractionReplyControllerAssign;
    property OnLccNodeTractionReplyControllerQuery: TOnLccNodeTractionControllerQuery read FOnLccNodeTractionReplyControllerQuery write FOnLccNodeTractionReplyControllerQuery;
    property OnLccNodeTractionReplyControllerChangeNotify: TOnLccNodeMessageResultCode read FOnLccNodeTractionReplyControllerChangeNotify write FOnLccNodeTractionReplyControllerChangeNotify;
    property OnLccNodeTractionReplyManage: TOnLccNodeMessageResultCode read FOnLccNodeTractionReplyManage write FOnLccNodeTractionReplyManage;
    property OnLccNodeTractionProxyReplyAllocate: TOnLccNodeTractionProxyReplyAllocate read FOnLccNodeTractionProxyReplyAllocate write FOnLccNodeTractionProxyReplyAllocate;
    property OnLccNodeTractionProxyReplyAttach: TOnLccNodeTractionProxyReplyAttach read FOnLccNodeTractionProxyReplyAttach write FOnLccNodeTractionProxyReplyAttach;
    property OnLccNodeTractionProxyReplyManage: TOnLccNodeMessageResultCode read FOnLccNodeTractionProxyReplyManage write FOnLccNodeTractionProxyReplyManage;
    {$ENDIF}
    property OnLccNodeVerifiedNodeID: TOnLccNodeMessage read FOnLccNodeVerifiedNodeID write FOnLccNodeVerifiedNodeID;
    property OnRequestMessageSend: TOnMessageEvent read FOnRequestMessageSend write FOnRequestMessageSend;
  end;


type
  TLccNetworkTreePropeties = (tp_NodeID, tp_AliasID, tp_ConsumedEvents, tp_ProducedEvents, tp_Snip, tp_Protocols, tp_Acid);
  TLccNetworkTreePropetiesSet = set of TLccNetworkTreePropeties;

 { TLccNetworkTree }

  TLccNetworkTree = class(TTreeView)
  private
    FConnected: Boolean;
    FNodeManager: TLccNodeManager;
    FNetworkTreeProperties: TLccNetworkTreePropetiesSet;
    FShowLocalNodes: Boolean;
    FShowRootNode: Boolean;
    FWorkerMessage: TLccMessage;
    procedure SetConnected(AValue: Boolean);
    procedure SetNetworkTreeProperties(AValue: TLccNetworkTreePropetiesSet);
    procedure SetShowLocalNodes(AValue: Boolean);
    procedure SetShowRootNode(AValue: Boolean);
  protected
    function FindOrCreateNewTreeNodeByLccNodeObject(LccNode: TLccNode): TTreeNode;
    function FindOrCreateNewTreeNodeByName(AParent: TTreeNode; AName: string; FindOnly: Boolean): TTreeNode;
    procedure DoAliasIDChanged(LccNode: TLccNode); virtual;
    procedure DoConsumerIdentified(SourceLccNode: TLccNode; var Event: TEventID; State: TEventState); virtual;
    procedure DoCreateLccNode(SourceLccNode: TLccNode); virtual;
    procedure DoDestroyLccNode(LccNode: TLccNode); virtual;
    procedure DoNodeIDChanged(LccNode: TLccNode); virtual;
    procedure DoProducerIdentified(SourceLccNode: TLccNode; var Event: TEventID; State: TEventState); virtual;
    procedure DoProtocolIdentifyReply(SourceLccNode, DestLccNode: TLccNode); virtual;
    procedure DoSimpleNodeIdentReply(SourceLccNode, DestLccNode: TLccNode); virtual;
    procedure DoVerifiedNodeID(SourceLccNode: TLccNode); virtual;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure ShowAliasIDChild(LccNode: TLccNode);
  public
    property WorkerMessage: TLccMessage read FWorkerMessage write FWorkerMessage;

    constructor Create(AnOwner: TComponent); override;
    destructor Destroy; override;
    procedure DirectScanLocalNodes;
    procedure InquireBasedOnNetworkTreeProperites(LccNode: TLccNode);
    procedure ScanNetwork;

  published
    property Connected: Boolean read FConnected write SetConnected;
    property NodeManager: TLccNodeManager read FNodeManager write FNodeManager;
    property NetworkTreeProperties: TLccNetworkTreePropetiesSet read FNetworkTreeProperties write SetNetworkTreeProperties;
    property ShowRootNode: Boolean read FShowRootNode write SetShowRootNode;
    property ShowLocallNodes: Boolean read FShowLocalNodes write SetShowLocalNodes;
  end;

var
  TotalSNIPMessages: DWord;
  TotalSTNIPMessage: DWord;

procedure Register;

// ******************************************************************************
// ******************************************************************************
// ******************************************************************************
// ******************************************************************************
// ******************************************************************************
// ******************************************************************************
// ******************************************************************************
// ******************************************************************************

implementation

procedure Register;
begin
  {$IFDEF FPC}
  {$I TLccNodeManager.lrs}
  {$ENDIF}
  RegisterComponents('LCC',[TLccNodeManager]);
  {$IFDEF FPC}
//  {$I TLccNetworkTree.lrs}
  {$ENDIF}
  RegisterComponents('LCC',[TLccNetworkTree]);
end;

{ TACDIMfg }

procedure TACDIMfg.LoadReply(LccMessage: TLccMessage; OutMessage: TLccMessage);
var
  i, Offset: Integer;
  ReadCount: Integer;
  Address: DWord;
  FlatArray: array[0..ACDI_MFG_SIZE - 1] of Byte;
  SNIP: TSimpleNodeInfo;
begin
  // Assumption is this is a datagram message
  ReadCount := LccMessage.ExtractDataBytesAsInt(7, 7);
  Address := LccMessage.ExtractDataBytesAsInt(2, 5);
  OutMessage.DataArrayIndexer[0] := LccMessage.DataArrayIndexer[0];
  OutMessage.DataArrayIndexer[1] := LccMessage.DataArrayIndexer[1] or $10;   // Make it a reply
  OutMessage.DataArrayIndexer[2] := LccMessage.DataArrayIndexer[2];          // Copy the address
  OutMessage.DataArrayIndexer[3] := LccMessage.DataArrayIndexer[3];
  OutMessage.DataArrayIndexer[4] := LccMessage.DataArrayIndexer[4];
  OutMessage.DataArrayIndexer[5] := LccMessage.DataArrayIndexer[5];
  OutMessage.DataArrayIndexer[6] := LccMessage.DataArrayIndexer[6];

  FillChar(FlatArray, ACDI_MFG_SIZE, #0);

  SNIP := (Owner as TLccOwnedNode).SimpleNodeInfo;
  FlatArray[0] := SNIP.Version;
  Offset := ACDI_MFG_OFFSET_MANUFACTURER;
  StringToNullArray(SNIP.Manufacturer, FlatArray, Offset);
  Offset := ACDI_MFG_OFFSET_MODEL;
  StringToNullArray(SNIP.Model, FlatArray, Offset);
  Offset := ACDI_MFG_OFFSET_HARDWARE_VERSION;
  StringToNullArray(SNIP.HardwareVersion, FlatArray, Offset);
  Offset := ACDI_MFG_OFFSET_SOFTWARE_VERSION;
  StringToNullArray(SNIP.SoftwareVersion, FlatArray, Offset);

  OutMessage.DataCount := ReadCount + 7;
  for i := 0 to ReadCount - 1 do
    OutMessage.DataArrayIndexer[i + 7] := FlatArray[Address + i];
  OutMessage.UserValid := True;
end;

{ TACDIUser }

procedure TACDIUser.LoadReply(LccMessage: TLccMessage; OutMessage: TLccMessage);
var
  i, Offset: Integer;
  ReadCount: Integer;
  Address: DWord;
  FlatArray: array[0..ACDI_USER_SIZE - 1] of Byte;
  SNIP: TSimpleNodeInfo;
begin
  // Assumption is this is a datagram message
  ReadCount := LccMessage.ExtractDataBytesAsInt(7, 7);
  Address := LccMessage.ExtractDataBytesAsInt(2, 5);
  OutMessage.DataArrayIndexer[0] := LccMessage.DataArrayIndexer[0];
  OutMessage.DataArrayIndexer[1] := LccMessage.DataArrayIndexer[1] or $10;   // Make it a reply
  OutMessage.DataArrayIndexer[2] := LccMessage.DataArrayIndexer[2];          // Copy the address
  OutMessage.DataArrayIndexer[3] := LccMessage.DataArrayIndexer[3];
  OutMessage.DataArrayIndexer[4] := LccMessage.DataArrayIndexer[4];
  OutMessage.DataArrayIndexer[5] := LccMessage.DataArrayIndexer[5];
  OutMessage.DataArrayIndexer[6] := LccMessage.DataArrayIndexer[6];

  FillChar(FlatArray, ACDI_USER_SIZE, #0);

  SNIP := (Owner as TLccOwnedNode).SimpleNodeInfo;
  FlatArray[0] := SNIP.UserVersion;
  Offset := ACDI_USER_OFFSET_NAME;
  StringToNullArray(SNIP.UserName, FlatArray, Offset);
  Offset := ACDI_USER_OFFSET_DESCRIPTION;
  StringToNullArray(SNIP.UserDescription, FlatArray, Offset);

  OutMessage.DataCount := ReadCount + 7;
  for i := 0 to ReadCount - 1 do
    OutMessage.DataArrayIndexer[i + 7] := FlatArray[Address + i];
  OutMessage.UserValid := True;
end;

procedure TACDIUser.WriteRequest(LccMessage: TLccMessage);
var
  Configuration: TConfiguration;
  Address: DWord;
begin
  // We should never allow the Version to be written too so never write to 0 offset
  Address := LccMessage.ExtractDataBytesAsInt(2, 5);
  if Address > 0 then
  begin
    Configuration := (Owner as TLccOwnedNode).Configuration;
    Configuration.WriteRequest(LccMessage);
  end;
end;

{ TLccDefaultRootNode }

constructor TLccDefaultRootNode.Create(AnOwner: TComponent);
var
  i: Integer;
begin
  inherited Create(AnOwner);
  // Common Protocols
  ProtocolSupport.Datagram := True;        // We support CDI so we must support datagrams
  ProtocolSupport.MemConfig := True;       // We support CDI so we must support datagrams
  ProtocolSupport.CDI := True;             // We Support CDI
  ProtocolSupport.EventExchange := True;   // We support Events
  ProtocolSupport.SimpleNodeInfo := True;  // We Support SNIP
  ProtocolSupport.ACDI := True;            // We Support ACDI

  // Setup the SNIP constants, this information MUST be idential to the information
  // in the  <identification> tag of the CDI to comply with the LCC specs
  SimpleNodeInfo.Version := SNIP_VER;
  SimpleNodeInfo.Manufacturer := SNIP_MFG;
  SimpleNodeInfo.Model := SNIP_MODEL;
  SimpleNodeInfo.SoftwareVersion := SNIP_SW_VER;
  SimpleNodeInfo.HardwareVersion := SNIP_HW_VER;
  SimpleNodeInfo.UserVersion := SNIP_USER_VER;
  SimpleNodeInfo.UserDescription := SNIP_USER_DESC;
  SimpleNodeInfo.UserName := SNIP_USER_NAME;

  // Setup a basic CDI
  CDI.AStream.Clear;
  for i := 0 to MAX_CDI_ARRAY - 1 do
    CDI.AStream.WriteByte(CDI_ARRAY[i]);
  CDI.Valid := True;

  // Setup the Configuraion Memory Options:
  ConfigMemOptions.HighSpace := MSI_CDI;
  ConfigMemOptions.LowSpace := MSI_ACDI_USER;
  ConfigMemOptions.SupportACDIMfgRead := True;
  ConfigMemOptions.SupportACDIUserRead := True;
  ConfigMemOptions.SupportACDIUserWrite := True;
  ConfigMemOptions.UnAlignedReads := True;
  ConfigMemOptions.UnAlignedWrites := True;
  ConfigMemOptions.WriteArbitraryBytes := True;
  ConfigMemOptions.WriteLenFourBytes := True;
  ConfigMemOptions.WriteLenOneByte := True;
  ConfigMemOptions.WriteLenSixyFourBytes := True;
  ConfigMemOptions.WriteLenTwoBytes := True;
  ConfigMemOptions.WriteStream := False;
  ConfigMemOptions.WriteUnderMask := False;

  // Setup the Configuration Memory Addres Space Information
  ConfigMemAddressSpaceInfo.Add(MSI_CDI, True, True, True, $00000000, $FFFFFFFF);
  ConfigMemAddressSpaceInfo.Add(MSI_ALL, True, True, True, $00000000, $FFFFFFFF);
  ConfigMemAddressSpaceInfo.Add(MSI_CONFIG, True, False, True, $00000000, $FFFFFFFF);
  ConfigMemAddressSpaceInfo.Add(MSI_ACDI_MFG, True, True, True, $00000000, $FFFFFFFF);      // We don't support ACDI in this object
  ConfigMemAddressSpaceInfo.Add(MSI_ACDI_USER, True, False, True, $00000000, $FFFFFFFF);    // We don't support ACDI in this object

end;

{ TConfigurationMemOptions }

procedure TConfigurationMemOptions.LoadReply(LccMessage: TLccMessage);
var
  OpsMask: Word;
begin
  LccMessage.DataArrayIndexer[0] := $20;
  LccMessage.DataArrayIndexer[1] := MCP_OP_GET_CONFIG_REPLY;
  LccMessage.DataArrayIndexer[5] := FHighSpace;
  LccMessage.DataArrayIndexer[6] := FLowSpace;
  LccMessage.DataArrayIndexer[4] := 0;
  if WriteLenOneByte then
    LccMessage.DataArrayIndexer[4] := LccMessage.DataArrayIndexer[4] or MCWL_ONE_BYTE;
  if WriteLenTwoBytes then
    LccMessage.DataArrayIndexer[4] := LccMessage.DataArrayIndexer[4] or MCWL_TWO_BYTE;
  if WriteLenFourBytes then
    LccMessage.DataArrayIndexer[4] := LccMessage.DataArrayIndexer[4] or MCWL_FOUR_BYTE;
  if WriteLenSixyFourBytes then
    LccMessage.DataArrayIndexer[4] := LccMessage.DataArrayIndexer[4] or MCWL_64_BYTE;
  if WriteArbitraryBytes then
    LccMessage.DataArrayIndexer[4] := LccMessage.DataArrayIndexer[4] or MCWL_ARBITRARY_BYTE;
  if WriteStream then
    LccMessage.DataArrayIndexer[4] := LccMessage.DataArrayIndexer[4] or MCWL_STREAM_WRITE_SUPPORTED;
  OpsMask := 0;
  if WriteUnderMask then
    OpsMask := OpsMask or MCO_WRITE_UNDER_MASK;
  if UnAlignedReads then
    OpsMask := OpsMask or MCO_UNALIGNED_READS;
  if UnAlignedWrites then
    OpsMask := OpsMask or MCO_UNALIGNED_WRITES;
  if SupportACDIMfgRead then
    OpsMask := OpsMask or MCO_ACDI_MFG_READS;
  if SupportACDIUserRead then
    OpsMask := OpsMask or MCO_ACDI_USER_READS;
  if SupportACDIUserWrite then
    OpsMask := OpsMask or MCO_ACDI_USER_WRITES;
  LccMessage.DataArrayIndexer[2] := _Hi(OpsMask);
  LccMessage.DataArrayIndexer[3] := _Lo(OpsMask);
  LccMessage.DataCount := 7;
  LccMessage.UserValid := True;
end;

function TConfigurationMemOptions.ProcessMessage(LccMessage: TLccMessage): Boolean;
var
  OpsMask: Word;
begin
  Result := True;
  if LccMessage.MTI = MTI_DATAGRAM then
  begin
    case LccMessage.DataArrayIndexer[1] of
      MCP_OP_GET_CONFIG_REPLY :
        begin
          FHighSpace := LccMessage.DataArrayIndexer[5];
          FLowSpace := LccMessage.DataArrayIndexer[6];
          FWriteLenOneByte := LccMessage.DataArrayIndexer[4] and MCWL_ONE_BYTE <> 0;
          FWriteLenTwoBytes := LccMessage.DataArrayIndexer[4] and MCWL_TWO_BYTE <> 0;
          FWriteLenFourBytes := LccMessage.DataArrayIndexer[4] and MCWL_FOUR_BYTE <> 0;
          FWriteLenSixyFourBytes := LccMessage.DataArrayIndexer[4] and MCWL_64_BYTE <> 0;
          FWriteArbitraryBytes := LccMessage.DataArrayIndexer[4] and MCWL_ARBITRARY_BYTE <> 0;
          FWriteStream := LccMessage.DataArrayIndexer[4] and MCWL_STREAM_WRITE_SUPPORTED <> 0;
          OpsMask := LccMessage.ExtractDataBytesAsInt(2, 3);
          FWriteUnderMask := OpsMask and MCO_WRITE_UNDER_MASK <> 0;
          FUnAlignedReads := OpsMask and MCO_UNALIGNED_READS <> 0;
          FUnAlignedWrites := OpsMask and MCO_UNALIGNED_WRITES <> 0;
          SupportACDIMfgRead := OpsMask and MCO_ACDI_MFG_READS <> 0;
          SupportACDIUserRead := OpsMask and MCO_ACDI_USER_READS <> 0;
          SupportACDIUserWrite := OpsMask and MCO_ACDI_USER_WRITES <> 0;
          Valid := True;
          OwnerManager.DoConfigMemOptionsReply(OwnerManager.FindSourceNode(LccMessage, True), OwnerManager.FindSourceNode(LccMessage, True));
        end;
    end
  end;
end;

{ TLccOwnedNode }

constructor TLccOwnedNode.Create(AnOwner: TComponent);
begin
  inherited Create(AnOwner);
  LoginTimer := TTimer.Create(Self);
  LoginTimer.Enabled := False;
  LoginTimer.Interval := 800;
  LoginTimer.OnTimer := {$IFDEF FPC}@{$ENDIF}OnLoginTimer;
  LogInAliasID := 0;
  FACDIMfg := TACDIMfg.Create(Self, MSI_ACDI_MFG);
  FACDIUser := TACDIUser.Create(Self, MSI_ACDI_USER);
  FConfiguration := TConfiguration.Create(Self, MSI_CONFIG);
end;

function TLccOwnedNode.CreateAliasID(var Seed: TNodeID; Regenerate: Boolean): Word;
begin
  if Regenerate then
    PsudoRandomNumberGeneratorOnSeed(Seed);
  Result := GenerateID_Alias_From_Seed(Seed);
  if Result = 0 then
  begin
    PsudoRandomNumberGeneratorOnSeed(Seed);
    Result := GenerateID_Alias_From_Seed(Seed);
  end;
end;

destructor TLccOwnedNode.Destroy;
begin
  if Permitted and Assigned(OwnerManager) then
  begin
    WorkerMessage.LoadAMR(NodeID, AliasID);
    OwnerManager.DoRequestMessageSend(WorkerMessage);
  end;
  FPermitted := False;
  FreeAndNil(FACDIMfg);
  FreeAndNil(FACDIUser);
  FreeAndNil(FConfiguration);
  inherited Destroy;
end;

function TLccOwnedNode.GenerateID_Alias_From_Seed(var Seed: TNodeID): Word;
begin
  Result := (Seed[0] xor Seed[1] xor (Seed[0] shr 12) xor (Seed[1] shr 12)) and $00000FFF;
end;

procedure TLccOwnedNode.GenerateNewNodeID;
begin
  FNodeID[1] := StrToInt('0x020112');
  FNodeID[0] := Random($FFFFFF);
  FSeedNodeID[0] := FNodeID[0];
  FSeedNodeID[1] := FNodeID[1];
end;

procedure TLccOwnedNode.Login(NewNodeID, RegenerateAliasSeed: Boolean);
var
  TempNodeID: TNodeID;
  TempID, TempID1, TempID2: QWord;
begin
  if Assigned(OwnerManager.LccSettings) then
  begin
    if OwnerManager.LccSettings.General.NodeIDAsVal = 0 then
    begin
      GenerateNewNodeID;
      OwnerManager.LccSettings.General.NodeIDAsTNodeID(TempNodeID);
      if not EqualNodeID(TempNodeID, NodeID, True) then
      begin
         TempID1 := QWord(NodeID[0]);
         TempID2 := QWord(NodeID[1]);
         TempID2 := TempID2 shl 24;
         TempID := TempID1 or TempID2;
         OwnerManager.LccSettings.General.NodeID := '0x'+IntToHex(TempID, 12);
         OwnerManager.LccSettings.SaveToFile;
      end;
    end else
    begin
      OwnerManager.LccSettings.General.NodeIDAsTNodeID(TempNodeID);
      FNodeID[0] := TempNodeID[0];
      FNodeID[1] := TempNodeID[1];
    end;
  end else
  begin
    if NewNodeID then
      GenerateNewNodeID;
  end;
  Configuration.LoadFromFile;
  if Assigned(OwnerManager) then
    OwnerManager.DoNodeIDChanged(Self);
  LoginAliasID := CreateAliasID(FSeedNodeID, RegenerateAliasSeed);
  SendAliasLoginRequest;
  DuplicateAliasDetected := False;
  LoginTimer.Enabled := True;
end;

procedure TLccOwnedNode.OnLoginTimer(Sender: TObject);
begin
  LoginTimer.Enabled := False;
  FAliasID := LoginAliasID;
  LogInAliasID := 0;
  if Assigned(OwnerManager) then
    OwnerManager.DoAliasIDChanged(Self);
  SendAliasLogin;
  SendEvents;
  if OwnerManager.RootNode = Self then
  begin
    if OwnerManager.AutoSendVerifyNodesOnStart then
    begin
      WorkerMessage.LoadVerifyNodeID(NodeID, AliasID);
      OwnerManager.DoRequestMessageSend(WorkerMessage);
    end;
  end;
end;

function TLccOwnedNode.ProcessMessage(LccMessage: TLccMessage): Boolean;
var
  TestNodeID: TNodeID;
  Event: TLccEvent;
  LccSourceNode: TLccNode;
begin
  Result := False;
  TestNodeID[0] := 0;
  TestNodeID[1] := 0;

  if LogInAliasID <> 0 then
  begin
    if LccMessage.CAN.SourceAlias = LogInAliasID then
    begin
      LogInAliasID := CreateAliasID(FNodeID, True);
      SendAliasLoginRequest;
      LoginTimer.Enabled := True;
      Exit;
    end;
  end;

  if Permitted then
  begin
    if LccMessage.CAN.SourceAlias = AliasID then
    begin
      if ((LccMessage.CAN.MTI and $0F000000) >= MTI_CAN_CID6) and ((LccMessage.CAN.MTI and $0F000000) <= MTI_CAN_CID0) then
      begin
        WorkerMessage.LoadRID(AliasID);                   // sorry charlie this is mine
        OwnerManager.DoRequestMessageSend(WorkerMessage);
        Exit;
      end else
      begin
        WorkerMessage.LoadAMR(NodeID, AliasID);          // You used my Alias you dog......
        OwnerManager.DoRequestMessageSend(WorkerMessage);
        FPermitted := False;
        Login(False, True);
        Exit;
      end;
    end;
  end;

  if LccMessage.HasDestination then
  begin
    if (LccMessage.CAN.DestAlias > 0) and (AliasID > 0) then
    begin
      if LccMessage.CAN.DestAlias <> AliasID then
        Exit;
    end else
    begin
      if not EqualNodeID(LccMessage.DestID, NodeID, False) then
        Exit;
    end;
    LccSourceNode := OwnerManager.FindSourceNode(LccMessage, True);
  end;

  if Permitted and Initialized then
  begin
    if LccMessage.IsCAN then
    begin
      case LccMessage.CAN.MTI of
        MTI_CAN_AME  :
            begin
              if LccMessage.DataCount = 6 then
              begin
                LccMessage.ExtractDataBytesAsNodeID(0, TestNodeID);
                if EqualNodeID(TestNodeID, NodeID, False) then
                begin
                  WorkerMessage.LoadAMD(NodeID, AliasID);
                  OwnerManager.DoRequestMessageSend(WorkerMessage);
                end
              end else
              begin
                WorkerMessage.LoadAMD(NodeID, AliasID);
                OwnerManager.DoRequestMessageSend(WorkerMessage);
              end;
              Result := True;
            end;
        MTI_CAN_AMD  :
            begin
              if LccMessage.DataCount = 6 then
              begin
                LccMessage.ExtractDataBytesAsNodeID(0, TestNodeID);
                if EqualNodeID(TestNodeID, NodeID, False) then                  // some Dog has my Node ID!
                begin
                  WorkerMessage.LoadPCER(NodeID, AliasID, @EVENT_DUPLICATE_ID_DETECTED);
                  OwnerManager.DoRequestMessageSend(WorkerMessage);
                end
              end;
              Result := True;
            end;
        MTI_CAN_RID  : begin end;
      end;
    end else
    begin
      case LccMessage.MTI of
        MTI_OPTIONAL_INTERACTION_REJECTED :
            begin
            end;
        MTI_VERIFY_NODE_ID_NUMBER      :
            begin
              if LccMessage.DataCount = 6 then
              begin
                LccMessage.ExtractDataBytesAsNodeID(0, TestNodeID);
                if EqualNodeID(TestNodeID, NodeID, False) then
                begin
                  WorkerMessage.LoadVerifiedNodeID(NodeID, AliasID);
                  OwnerManager.DoRequestMessageSend(WorkerMessage);
                end
              end else
              begin
                WorkerMessage.LoadVerifiedNodeID(NodeID, AliasID);
                OwnerManager.DoRequestMessageSend(WorkerMessage);
              end;
              Result := True;
            end;
        MTI_VERIFY_NODE_ID_NUMBER_DEST :
            begin
              WorkerMessage.LoadVerifiedNodeID(NodeID, AliasID);
              OwnerManager.DoRequestMessageSend(WorkerMessage);
              Result := True;
            end;
        MTI_VERIFIED_NODE_ID_NUMBER :
            begin

            end;
        MTI_SIMPLE_NODE_INFO_REQUEST :
            begin
              WorkerMessage.LoadSimpleNodeIdentInfoReply(NodeID, AliasID, LccMessage.SourceID, LccMessage.CAN.SourceAlias, SimpleNodeInfo.PackedFormat);
              OwnerManager.DoRequestMessageSend(WorkerMessage);
              Result := True;
            end;
        MTI_SIMPLE_NODE_INFO_REPLY :
            begin               // Called if I send a SNIP;
              ProtocolSupport.ProcessMessage(LccMessage);
              if Assigned(OwnerManager) then
                OwnerManager.DoSimpleNodeIdentReply(LccSourceNode, Self);
              Result := True;
            end;
        MTI_PROTOCOL_SUPPORT_INQUIRY :
            begin
              WorkerMessage.LoadProtocolIdentifyReply(NodeID, AliasID, LccMessage.SourceID, LccMessage.CAN.SourceAlias, ProtocolSupport.EncodeFlags);
              OwnerManager.DoRequestMessageSend(WorkerMessage);
              Result := True;
            end;
        MTI_PROTOCOL_SUPPORT_REPLY :
            begin   // Called if I send a Protocol Support
              ProtocolSupport.ProcessMessage(LccMessage);
              if Assigned(OwnerManager) then
                OwnerManager.DoProtocolIdentifyReply(LccSourceNode, Self);
              Result := True;
            end;
        MTI_EVENTS_IDENTIFY :
            begin
              SendConsumedEvents;
              SendProducedEvents;
              Result := True;
            end;
        MTI_EVENTS_IDENTIFY_DEST :
            begin
              if AliasID = LccMessage.CAN.DestAlias then
              begin
                SendConsumedEvents;
                SendProducedEvents;
              end;
              Result := True;
            end;
        MTI_PRODUCER_IDENDIFY :
            begin
              Event := EventsProduced.Supports(LccMessage.ExtractDataBytesAsEventID(0)^);
              if Assigned(Event) then
              begin
                WorkerMessage.LoadProducerIdentified(NodeID, AliasID, Event.FID, Event.State);
                OwnerManager.DoRequestMessageSend(WorkerMessage);
              end;
              Result := True;
            end;
        MTI_CONSUMER_IDENTIFY :
            begin
              Event := EventsConsumed.Supports(LccMessage.ExtractDataBytesAsEventID(0)^);
              if Assigned(Event) then
              begin
                WorkerMessage.LoadConsumerIdentified(NodeID, AliasID, Event.FID, Event.State);
                OwnerManager.DoRequestMessageSend(WorkerMessage);
              end;
              Result := True;
            end;
         MTI_CONSUMER_IDENTIFIED_CLEAR :
            begin
            end;
         MTI_CONSUMER_IDENTIFIED_SET :
            begin
            end;
         MTI_CONSUMER_IDENTIFIED_UNKNOWN :
            begin
            end;
         MTI_PRODUCER_IDENTIFIED_CLEAR :
            begin
            end;
         MTI_PRODUCER_IDENTIFIED_SET :
            begin
            end;
         MTI_PRODUCER_IDENTIFIED_UNKNOWN :
            begin
            end;
         MTI_DATAGRAM_REJECTED_REPLY :
           begin
             // This is passed by the assembler/disassembler if something went wrong that needs to
             // get passed on
             LccMessage.SwapDestAndSourceIDs;
             OwnerManager.DoRequestMessageSend(LccMessage);
             Result := True;
           end;
         MTI_DATAGRAM :
           begin
             case LccMessage.DataArrayIndexer[0] of
               DATAGRAM_PROTOCOL_CONFIGURATION :
                 begin
                   case LccMessage.DataArrayIndexer[1] and $F0 of
                     MCP_WRITE :
                       begin
                         case LccMessage.DataArrayIndexer[1] and $03 of
                           MCP_NONE :
                               begin
                                 case LccMessage.DataArrayIndexer[6] of
                                   MSI_CDI             :
                                       begin
                                       end;  // Not writeable
                                   MSI_ALL             :
                                       begin
                                       end;  // Not writeable
                                   MSI_CONFIG          :
                                       begin
                                         SendAckReply(LccMessage);
                                         Configuration.WriteRequest(LccMessage);
                                         Result := True;
                                       end;
                                   MSI_ACDI_MFG        :
                                       begin
                                       end;  // Not writeable
                                   MSI_ACDI_USER       :
                                       begin
                                         SendAckReply(LccMessage);
                                         ACDIUser.WriteRequest(LccMessage);
                                         Result := True;
                                       end;
                                   {$IFDEF TRACTION}
                                   MSI_FDI             :
                                       begin
                                       end;  // Not writeable
                                   MSI_FUNCTION_CONFIG :
                                       begin
                                       end;
                                   {$ENDIF}
                                 end
                               end;
                           MCP_CONFIGURATION :
                               begin
                                 SendAckReply(LccMessage);         // TODO: Add Reply ability
                                 Configuration.WriteRequest(LccMessage);
                                 Result := True;
                               end;
                           MCP_ALL           :
                               begin
                               end; // Not writeable
                           MCP_CDI           :
                               begin
                               end; // Not writeable
                         end;
                       end;
                     MCP_WRITE_STREAM :
                         begin
                         end;
                     MCP_READ :
                         begin
                           case LccMessage.DataArrayIndexer[1] and $03 of
                             MCP_NONE :
                                 begin
                                   case LccMessage.DataArrayIndexer[6] of
                                     MSI_CDI             :
                                         begin
                                           SendAckReply(LccMessage);
                                           WorkerMessage.LoadDatagram(NodeID, AliasID, LccMessage.SourceID, LccMessage.CAN.SourceAlias);
                                           CDI.LoadReply(LccMessage, WorkerMessage);
                                           if WorkerMessage.UserValid then
                                            OwnerManager.DoRequestMessageSend(WorkerMessage);
                                           Result := True;
                                         end;
                                     MSI_ALL             :
                                         begin
                                         end;
                                     MSI_CONFIG          :
                                         begin
                                           SendAckReply(LccMessage);
                                           WorkerMessage.LoadDatagram(NodeID, AliasID, LccMessage.SourceID, LccMessage.CAN.SourceAlias);
                                           Configuration.LoadReply(LccMessage, WorkerMessage);
                                           if WorkerMessage.UserValid then
                                            OwnerManager.DoRequestMessageSend(WorkerMessage);
                                           Result := True;
                                         end;
                                     MSI_ACDI_MFG        :
                                         begin
                                           SendAckReply(LccMessage);
                                           WorkerMessage.LoadDatagram(NodeID, AliasID, LccMessage.SourceID, LccMessage.CAN.SourceAlias);
                                           ACDIMfg.LoadReply(LccMessage, WorkerMessage);
                                           if WorkerMessage.UserValid then
                                            OwnerManager.DoRequestMessageSend(WorkerMessage);
                                           Result := True;
                                         end;
                                     MSI_ACDI_USER       :
                                         begin
                                           SendAckReply(LccMessage);
                                           WorkerMessage.LoadDatagram(NodeID, AliasID, LccMessage.SourceID, LccMessage.CAN.SourceAlias);
                                           ACDIUser.LoadReply(LccMessage, WorkerMessage);
                                           if WorkerMessage.UserValid then
                                            OwnerManager.DoRequestMessageSend(WorkerMessage);
                                           Result := True;
                                         end;
                                     {$IFDEF TRACTION}
                                     MSI_FDI             :
                                          begin
                                          end;
                                     MSI_FUNCTION_CONFIG :
                                          begin
                                          end;
                                     {$ENDIF}
                                   end
                                 end;
                             MCP_CONFIGURATION : begin
                                                   SendAckReply(LccMessage);
                                                   WorkerMessage.LoadDatagram(NodeID, AliasID, LccMessage.SourceID, LccMessage.CAN.SourceAlias);
                                                   Configuration.LoadReply(LccMessage, WorkerMessage);
                                                   if WorkerMessage.UserValid then
                                                     OwnerManager.DoRequestMessageSend(WorkerMessage);
                                                   Result := True;
                                                 end;
                             MCP_ALL           : begin  end;
                             MCP_CDI           : begin
                                                   SendAckReply(LccMessage);
                                                   WorkerMessage.LoadDatagram(NodeID, AliasID, LccMessage.SourceID, LccMessage.CAN.SourceAlias);
                                                   CDI.LoadReply(LccMessage, WorkerMessage);
                                                   if WorkerMessage.UserValid then
                                                     OwnerManager.DoRequestMessageSend(WorkerMessage);
                                                   Result := True;
                                                 end;
                           end;
                         end;
                     MCP_READ_STREAM :
                         begin
                         end;
                     MCP_OPERATION :
                         begin
                           case LccMessage.DataArrayIndexer[1] of
                             MCP_OP_GET_CONFIG :
                                 begin
                                   WorkerMessage.LoadDatagram(NodeID, AliasID, LccMessage.SourceID, LccMessage.CAN.SourceAlias);
                                   ConfigMemOptions.LoadReply(WorkerMessage);
                                   if WorkerMessage.UserValid then;
                                     OwnerManager.DoRequestMessageSend(WorkerMessage);
                                   Result := True;
                                 end;
                             MCP_OP_GET_ADD_SPACE_INFO :
                                 begin
                                   WorkerMessage.LoadDatagram(NodeID, AliasID, LccMessage.SourceID, LccMessage.CAN.SourceAlias);
                                   ConfigMemAddressSpaceInfo.LoadReply(LccMessage, WorkerMessage);
                                   if WorkerMessage.UserValid then
                                     OwnerManager.DoRequestMessageSend(WorkerMessage);
                                   Result := True;
                                 end;
                             MCP_OP_LOCK :
                                 begin
                                 end;
                             MCP_OP_GET_UNIQUEID :
                                 begin
                                 end;
                             MCP_OP_FREEZE :
                                 begin
                                 end;
                             MCP_OP_INDICATE :
                                 begin
                                 end;
                             MCP_OP_RESETS :
                                 begin
                                 end;
                           end // case
                         end
                   end; // case
                 end
             else begin
                 // Undknown Datagram Type
                 WorkerMessage.LoadDatagramRejected(NodeID, AliasID, LccMessage.SourceID, LccMessage.CAN.SourceAlias, REJECTED_DATAGRAMS_NOT_ACCEPTED);
                 OwnerManager.DoRequestMessageSend(WorkerMessage);
                 Result := True;
               end;
             end;  // case
           end;
      else begin
          if LccMessage.HasDestination then
          begin
            WorkerMessage.LoadOptionalInteractionRejected(NodeID, AliasID, LccMessage.SourceID, LccMessage.CAN.SourceAlias, REJECTED_BUFFER_FULL, LccMessage.MTI);
            OwnerManager.DoRequestMessageSend(WorkerMessage);
            Result := True;
          end;
        end;
      end; // case
    end;
  end;
end;

procedure TLccOwnedNode.PsudoRandomNumberGeneratorOnSeed(var Seed: TNodeID);
var
  temp1,              // Upper 24 Bits of temp 48 bit number
  temp2: DWORD;       // Lower 24 Bits of temp 48 Bit number
begin
  temp1 := ((Seed[1] shl 9) or ((Seed[0] shr 15) and $000001FF)) and $00FFFFFF;   // x(i+1)(2^9 + 1)*x(i) + C  = 2^9 * x(i) + x(i) + C
  temp2 := (Seed[0] shl 9) and $00FFFFFF;                                                                  // Calculate 2^9 * x

  Seed[0] := Seed[0] + temp2 + $7A4BA9;   // Now y = 2^9 * x so all we have left is x(i+1) = y + x + c
  Seed[1] := Seed[1] + temp1 + $1B0CA3;

  Seed[1] := (Seed[1] and $00FFFFFF) or (Seed[0] and $FF000000) shr 24;   // Handle the carries of the lower 24 bits into the upper
  Seed[0] := Seed[0] and $00FFFFFF;
end;

procedure TLccOwnedNode.SendAliasLogin;
begin
  if Assigned(OwnerManager) then
  begin
    WorkerMessage.LoadRID(AliasID);
    OwnerManager.DoRequestMessageSend(WorkerMessage);
    WorkerMessage.LoadAMD(NodeID, AliasID);
    OwnerManager.DoRequestMessageSend(WorkerMessage);
    FPermitted := True;
    WorkerMessage.LoadInitializationComplete(NodeID, AliasID);
    OwnerManager.DoRequestMessageSend(WorkerMessage);
    FInitialized := True;
  end;
end;

procedure TLccOwnedNode.SendAliasLoginRequest;
begin
  if Assigned(OwnerManager) then
  begin
    WorkerMessage.LoadCID(NodeID, LoginAliasID, 0);
    OwnerManager.DoRequestMessageSend(WorkerMessage);
    WorkerMessage.LoadCID(NodeID, LoginAliasID, 1);
    OwnerManager.DoRequestMessageSend(WorkerMessage);
    WorkerMessage.LoadCID(NodeID, LoginAliasID, 2);
    OwnerManager.DoRequestMessageSend(WorkerMessage);
    WorkerMessage.LoadCID(NodeID, LoginAliasID, 3);
    OwnerManager.DoRequestMessageSend(WorkerMessage);
  end;
end;

procedure TLccOwnedNode.SendAMR;
begin
   WorkerMessage.LoadAMR(NodeID, AliasID);
   OwnerManager.DoRequestMessageSend(WorkerMessage);
end;

procedure TLccOwnedNode.SendConsumedEvents;
var
  i: Integer;
begin
  for i := 0 to EventsConsumed.EventList.Count - 1 do
  begin
    WorkerMessage.LoadConsumerIdentified(NodeID, AliasID, EventsConsumed.Event[i].FID, EventsConsumed.Event[i].State);
    OwnerManager.DoRequestMessageSend(WorkerMessage);
  end;
end;

procedure TLccOwnedNode.SendEvents;
begin
  SendConsumedEvents;
  SendProducedEvents;
end;

procedure TLccOwnedNode.SendProducedEvents;
var
  i: Integer;
begin
  for i := 0 to EventsProduced.EventList.Count - 1 do
  begin
    WorkerMessage.LoadProducerIdentified(NodeID, AliasID, EventsProduced.Event[i].FID , EventsProduced.Event[i].State);
    OwnerManager.DoRequestMessageSend(WorkerMessage);
  end;
end;

{$IFDEF TRACTION}
{ TFunctionConfiguration }

function TFunctionConfiguration.GetFunctionStates(iIndex: Integer): Boolean;
begin
  if (iIndex > -1) and (iIndex < 30) then
    Result := FFunctionStatesArray[iIndex] = 1
  else
    Result := False;
end;
{$ENDIF}

{$IFDEF TRACTION}
function TFunctionConfiguration.ProcessMessage(LccMessage: TLccMessage): Boolean;
var
  SourceNode, DestNode: TLccNode;
  FunctionAddress: DWord;
  i: Integer;
begin
  Result := False;
  FunctionAddress := LccMessage.ExtractDataBytesAsInt(2, 5);
  FunctionAddress := FunctionAddress and $000000FF;
  i := 7;
  if (LccMessage.DataCount - i) mod 2 = 0 then   // Words are 2 bytes so make sure we are on even boundy of words
  begin
    while i < LccMessage.DataCount do
    begin
      FFunctionStatesArray[FunctionAddress] := (LccMessage.DataArrayIndexer[i+1] shl 8) or LccMessage.DataArrayIndexer[i]; // Little
      Inc(FunctionAddress);
      Inc(i, 2);
    end;
    Valid := True;
    if Assigned(OwnerManager) then
    begin
      SourceNode := OwnerManager.FindSourceNode(LccMessage);
      DestNode := OwnerManager.FindDestNode(LccMessage);
      if Assigned(SourceNode) and Assigned(DestNode) then
        OwnerManager.DoFunctionConfiguration(SourceNode, DestNode);
    end;
  end;
end;
{$ENDIF}

{ TLccEvents }

constructor TLccEvents.Create(AnOwner: TComponent);
begin
  inherited Create(AnOwner);
  {$IFDEF FPC}
    FEventList := TList.Create;
  {$ELSE}
    FEventList := TObjectList<TLccEvent>.Create;
    EventList.OwnsObjects := False;
  {$ENDIF}
end;

destructor TLccEvents.Destroy;
begin
  Clear;
  FreeAndNil(FEventList);
  inherited Destroy;
end;

function TLccEvents.GetEvent(Index: Integer): TLccEvent;
begin
  {$IFDEF FPC}
    Result := TLccEvent( EventList[Index])
  {$ELSE}
    Result := EventList[Index]
  {$ENDIF}
end;

function TLccEvents.GetEventIDAsStr(Index: Integer): string;
begin
  Result := EventIDToString(Event[Index].ID);
end;

function TLccEvents.GetCount: Integer;
begin
  Result := EventList.Count;
end;

function TLccEvents.ProcessMessage(LccMessage: TLccMessage): Boolean;
begin
  Result := False;
end;

procedure TLccEvents.Add(Event: TEventID; State: TEventState);
var
  LccEvent: TLccEvent;
begin
  LccEvent := Supports(Event);
  if Assigned(LccEvent) then
    LccEvent.State := State
  else begin
    LccEvent := TLccEvent.Create;
    LccEvent.ID := Event;
    LccEvent.State := State;
    EventList.Add(LccEvent);
  end;
end;

procedure TLccEvents.Clear;
var
  i: Integer;
begin
  try
    for i := 0 to EventList.Count - 1 do
    {$IFDEF FPC}
      TObject( EventList[i]).Free;
    {$ELSE}
      EventList[i].Free;
    {$ENDIF}
  finally
    EventList.Clear
  end;
end;

function TLccEvents.Supports(Event: TEventID): TLccEvent;
var
  i: Integer;
begin
  Result := nil;
  i := 0;
  while not Assigned(Result) and (i < EventList.Count) do
  begin
    if EqualEventID(Event, TLccEvent( EventList[i]).ID) then
      Result := TLccEvent( EventList[i]);
    Inc(i);
  end;

end;

{ TConfigurationMemory }

constructor TConfigurationMemory.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
end;

destructor TConfigurationMemory.Destroy;
begin
  inherited Destroy;
end;

function TConfigurationMemory.GetDataRawIndexer(iIndex: Word): Byte;
begin
  Result := FDataRaw[iIndex]
end;

procedure TConfigurationMemory.Initialize(AnAddress: DWord;
  AnAddressSpace: Byte; DataSize: Integer; ADataType: TLccConfigDataType);
begin
  ErrorCode := 0;
  Address := AnAddress;
  DataCount := DataSize;
  AddressSpace := AnAddressSpace;
  InProcessAddress := AnAddress;
  DataType := ADataType;
  Valid := False;
  FDataTypeInteger := 0;
  FDataTypeEvent[0] := 0;
  FDataTypeEvent[1] := 0;
  FDataTypeEvent[2] := 0;
  FDataTypeEvent[3] := 0;
  FDataTypeEvent[4] := 0;
  FDataTypeEvent[5] := 0;
  FDataTypeEvent[6] := 0;
  FDataTypeEvent[7] := 0;
  FDataTypeBit := 0;
  FDataTypeString := '';
end;

function TConfigurationMemory.ProcessMessage(LccMessage: TLccMessage): Boolean;
var
  iStart, i, RemainingCount: Integer;

  LocalAddressSpace: Byte;
  SourceNode: TLccNode;
begin
  Result := True;
  LocalAddressSpace := 0;
  RemainingCount := 0;
  if LccMessage.DataArrayIndexer[1] and MCP_READ_REPLY = MCP_READ_REPLY then
  begin
    // First Block of Data
    if InProcessAddress = Address then
    begin
      if LccMessage.DataArrayIndexer[1] and $03 <> 0 then
      begin
         case LccMessage.DataArrayIndexer[1] and $03 of
           MCP_CDI           : LocalAddressSpace := MSI_CDI;
           MCP_ALL           : LocalAddressSpace := MSI_ALL;
           MCP_CONFIGURATION : LocalAddressSpace := MSI_CONFIG;
         end;
         iStart := 6;
      end else
      begin
         LocalAddressSpace := LccMessage.DataArrayIndexer[6];
         iStart := 7
      end;
      if LocalAddressSpace <> AddressSpace then
        ErrorCode := ErrorCode or ERROR_CONFIGMEM_ADDRESS_SPACE_MISMATCH;
    end else
    begin
      // Subsequent Blocks of Data
      if LccMessage.DataArrayIndexer[1] and $03 <> 0 then
        iStart := 6
      else
        iStart := 7
    end;

    DataCount := 0;
    if ErrorCode = 0 then
    begin
      DataCount := LccMessage.DataCount - iStart;
      for i := 0 to DataCount - 1 do
        DataRawIndexer[i] := LccMessage.DataArrayIndexer[i + iStart];
      case DataType of
        cdt_String :
          begin
            InProcessAddress := InProcessAddress + DWord((LccMessage.DataCount - iStart));
            for i := 0 to LccMessage.DataCount - iStart - 1 do
              FDataTypeString := FDataTypeString + Char( LccMessage.DataArrayIndexer[i+iStart]);

            RemainingCount := DataCount - Length(FDataTypeString);           // Strings are 1 indexed
            if RemainingCount > 64 then
              RemainingCount := 64;
            if RemainingCount > 0 then
            begin
              WorkerMessage.LoadConfigMemRead(LccMessage.DestID, LccMessage.CAN.DestAlias, LccMessage.SourceID, LccMessage.CAN.SourceAlias, MSI_CONFIG, InProcessAddress, RemainingCount);
              OwnerManager.DoRequestMessageSend(WorkerMessage);
            end
          end;
        cdt_Int :
          begin
            FDataTypeInteger := LccMessage.ExtractDataBytesAsInt(iStart, LccMessage.DataCount-1);
            RemainingCount := 0;
          end;
        cdt_EventID :
          begin
            FDataTypeEvent := LccMessage.ExtractDataBytesAsEventID(iStart)^;
            RemainingCount := 0;
          end;
        cdt_Bit :
          begin
            // ToDo
          end;
       end
    end;

    if (ErrorCode = 0) or (RemainingCount <= 0) then
    begin
      Valid := ErrorCode = 0;
      SourceNode := OwnerManager.FindSourceNode(LccMessage, True);
      if Assigned(OwnerManager.CdiParser) then    // Callback on the CDI Parser if available
        OwnerManager.CdiParser.DoConfigMemReadReply(SourceNode);
      OwnerManager.DoConfigMemReadReply(SourceNode, OwnerManager.FindDestNode(LccMessage, True));
    end;
  end else
  if LccMessage.DataArrayIndexer[1] and MCP_WRITE_REPLY <> 0 then
  begin
    ErrorCode := 0;

    if ErrorCode = 0 then
    begin
      SourceNode := OwnerManager.FindSourceNode(LccMessage, True);
      if Assigned(OwnerManager.CdiParser) then    // Callback on the CDI Parser if available
        OwnerManager.CdiParser.DoConfigMemWriteReply(SourceNode);
      OwnerManager.DoConfigMemWriteReply(SourceNode, OwnerManager.FindDestNode(LccMessage, True));
    end;
  end;
end;

procedure TConfigurationMemory.SetDataRawIndexer(iIndex: Word; const Value: Byte);
begin
  FDataRaw[iIndex] := Value
end;

{TCDI}

procedure TCDI.DoLoadComplete(LccMessage: TLccMessage);
var
  SourceNode, DestNode: TLccNode;
begin
  if Assigned(OwnerManager) then
  begin
    SourceNode := OwnerManager.FindSourceNode(LccMessage, True);
    DestNode := OwnerManager.FindDestNode(LccMessage, True);
    if Assigned(SourceNode) and Assigned(DestNode) then
      OwnerManager.DoCDI(SourceNode, DestNode);
  end;
end;

function TCDI.LoadFromXml(CdiFilePath: string): Boolean;
var
  XmlFile: TStringList;
  i, j, AsciiArrayCount: Integer;
begin
  Result := False;
  if FileExists(CdiFilePath) then
  begin
    XmlFile := TStringList.Create;
    try
      XmlFile.LoadFromFile(CdiFilePath);
      XmlFile.Text := Trim(XmlFile.Text);
      AStream.Clear;
      AsciiArrayCount := 0;
      for i := 0 to XmlFile.Count - 1 do
      begin
        if Length(XmlFile[i]) > 0 then
        begin
          for j := 1 to Length(XmlFile[i]) do
          begin
            AStream.WriteByte(Ord(XmlFile[i][j]));
            Inc(AsciiArrayCount)
          end;
        end
      end;
      Result := True;
    finally
      FreeAndNil(XmlFile);
    end;
  end;
end;

{$IFDEF TRACTION}
{ TFDI }

procedure TFDI.DoLoadComplete(LccMessage: TLccMessage);
var
  SourceNode, DestNode: TLccNode;
begin
  if Assigned(OwnerManager) then
  begin
    SourceNode := OwnerManager.FindSourceNode(LccMessage);
    DestNode := OwnerManager.FindDestNode(LccMessage);
    if Assigned(SourceNode) and Assigned(DestNode) then
      OwnerManager.DoFDI(SourceNode, DestNode);
  end;
end;
{$ENDIF}

{$IFDEF TRACTION}
{ TTraction }

procedure TTraction.SetFunctions(Index: DWord; AValue: Word);
begin
  GrowArray(Index + 1);
  FunctionArray[Index] := AValue
end;

function TTraction.GetFunctions(Index: DWord): Word;
begin
  GrowArray(Index + 1);
  Result := FunctionArray[Index];
end;

procedure TTraction.GrowArray(NewSize: DWord);
var
  OldSize, i: DWord;
begin
  OldSize := Length(FunctionArray);
  if NewSize > OldSize then
  begin
    SetLength(FunctionArray, NewSize);
    i := OldSize;
    while i < NewSize do
    begin
      FunctionArray[i] := 0;
      Inc(i)
    end
  end;
end;

function TTraction.IsLinked: Boolean;
begin
  Result := Assigned(LinkedNode)
end;

function TTraction.ProcessMessage(LccMessage: TLccMessage): Boolean;
begin
  Result := True;
  case LccMessage.DataArrayIndexer[0] of
    TRACTION_QUERY_SPEED :
        begin
          FSpeed := LccMessage.ExtractDataBytesAsInt(1, 2);
          FSpeedCommanded := LccMessage.ExtractDataBytesAsInt(4, 5);
          FSpeedActual := LccMessage.ExtractDataBytesAsInt(6, 7); ;
        end;
    TRACTION_QUERY_FUNCTION :
        begin
          SetFunctions(LccMessage.ExtractDataBytesAsInt(1, 3), LccMessage.ExtractDataBytesAsInt(4,5))
        end;
    TRACTION_CONTROLLER_CONFIG :
        begin
          case LccMessage.DataArrayIndexer[1] of
            TRACTION_CONTROLLER_CONFIG_ASSIGN :
                begin

                end;
            TRACTION_CONTROLLER_CONFIG_QUERY :
                begin

                end;
            TRACTION_CONTROLLER_CONFIG_NOTIFY :
                begin

                end;
          end;
        end;
    TRACTION_CONSIST :
        begin

        end;
    TRACTION_MANAGE :
        begin

        end;
  end;
end;
{$ENDIF}

{ TNodeProtocolBase }

procedure TNodeProtocolBase.SetOwnerManager(AValue: TLccNodeManager);
begin
  if FOwnerManager=AValue then Exit;
  FOwnerManager:=AValue;
end;

procedure TNodeProtocolBase.SetValid(AValue: Boolean);
begin
  if FValid=AValue then Exit;
  FValid:=AValue;
end;

constructor TNodeProtocolBase.Create(AnOwner: TComponent);
begin
  inherited Create(AnOwner);
  FCreateTime := GetTickCount;
  FWorkerMessage := TLccMessage.Create;
end;

destructor TNodeProtocolBase.Destroy;
begin
  FreeAndNil(FWorkerMessage);
  inherited Destroy;
end;

{ TLccNodeManager }

function TLccNodeManager.GetNodes(Index: Integer): TLccNode;
begin
  Result := TLccNode( NodeList[Index]);
end;

function TLccNodeManager.GetOwnedNodes(Index: Integer): TLccOwnedNode;
begin
  Result := TLccOwnedNode( OwnedNodeList[Index]);
end;

function TLccNodeManager.GetRootNodeAlias: Word;
begin
  Result := RootNode.AliasID;
end;

function TLccNodeManager.GetRootNodeID: TNodeID;
begin
  Result := RootNode.NodeID;
end;

procedure TLccNodeManager.SetCAN(AValue: Boolean);
begin
  if AValue <> FCAN then
  begin
    FCAN:=AValue;
    if Enabled then
    begin
      Enabled := False;                                                         // ReEnable if the CAN is set while enabled
      Enabled := True;
    end;
  end;
end;

procedure TLccNodeManager.SetEnabled(AValue: Boolean);
begin
  if AValue <> FEnabled then
  begin
    FEnabled := AValue;
    if FEnabled then
    begin
      if Assigned(RootNode) then
        RootNode.Login(True, False);
    end else
    begin
      if Assigned(NetworkTree) then
        NetworkTree.Connected := False;
      Clear;
      ClearOwned;
      RootNode.SendAMR;
    end
  end
end;

procedure TLccNodeManager.SetNodes(Index: Integer; AValue: TLccNode);
begin
  NodeList[Index] := AValue
end;

procedure TLccNodeManager.SetOwnedNodes(Index: Integer; AValue: TLccOwnedNode);
begin
  OwnedNodeList[Index] := AValue
end;

procedure TLccNodeManager.DoAliasIDChanged(LccNode: TLccNode);
begin
  if Assigned(NetworkTree) then
    NetworkTree.DoAliasIDChanged(LccNode);
  if Assigned(OnAliasIDChanged) then
    OnAliasIDChanged(Self, LccNode);
end;

procedure TLccNodeManager.DoCDI(SourceLccNode, DestLccNode: TLccNode);
begin
  if Assigned(OnLccNodeCDI) then
    OnLccNodeCDI(Self, SourceLccNode, DestLccNode)
end;

procedure TLccNodeManager.DoConfigMemAddressSpaceInfoReply(SourceLccNode,
  DestLccNode: TLccNode; AddressSpace: Byte);
begin
 if Assigned(OnLccNodeConfigMemAddressSpaceInfoReply) then
   OnLccNodeConfigMemAddressSpaceInfoReply(Self, SourceLccNode, DestLccNode, AddressSpace);
end;

procedure TLccNodeManager.DoConfigMemOptionsReply(SourceLccNode,
  DestLccNode: TLccNode);
begin
  if Assigned(OnLccNodeConfigMemOptionsReply) then
    OnLccNodeConfigMemOptionsReply(Self, SourceLccNode, DestLccNode);
end;

procedure TLccNodeManager.DoConfigMemReadReply(SourceLccNode,
  DestLccNode: TLccNode);
begin
  if Assigned(OnLccNodeConfigMemReadReply) then
    OnLccNodeConfigMemReadReply(Self, SourceLccNode, DestLccNode);
end;

procedure TLccNodeManager.DoConfigMemWriteReply(SourceLccNode, DestLccNode: TLccNode);
begin
  if Assigned(OnLccNodeConfigMemWriteReply) then
    OnLccNodeConfigMemWriteReply(Self, SourceLccNode, DestLccNode);
end;

procedure TLccNodeManager.DoCreateLccNode(SourceLccNode: TLccNode);
begin
  if Assigned(NetworkTree) then
    NetworkTree.DoCreateLccNode(SourceLccNode);
  if Assigned(OnLccNodeCreate) then
    OnLccNodeCreate(Self, SourceLccNode)
end;

procedure TLccNodeManager.DoConsumerIdentified(SourceLccNode: TLccNode; var Event: TEventID; State: TEventState);
begin
  if Assigned(NetworkTree) then
    NetworkTree.DoConsumerIdentified(SourceLccNode, Event, State);
  if Assigned(OnLccNodeConsumerIdentified) then
    OnLccNodeConsumerIdentified(Self, SourceLccNode, Event, State);
end;

procedure TLccNodeManager.DoDatagramReply(SourceLccNode,
  DestLccNode: TLccNode);
begin
  if Assigned(OnLccNodeDatagramReply) then
    OnLccNodeDatagramReply(Self, SourceLccNode, DestLccNode);
end;

procedure TLccNodeManager.DoDestroyLccNode(LccNode: TLccNode);
begin
  if not (csDestroying in ComponentState) then
  begin
    if Assigned(CdiParser) then
      CdiParser.NotifyLccNodeDestroy(LccNode);
  end;
  if Assigned(NetworkTree) then
    NetworkTree.DoDestroyLccNode(LccNode);
  if Assigned(OnLccNodeDestroy) then
    OnLccNodeDestroy(Self, LccNode);
end;

{$IFDEF TRACTION}
procedure TLccNodeManager.DoFDI(SourceLccNode, DestLccNode: TLccNode);
begin
  if Assigned(OnLccNodeFDI) then
    OnLccNodeFDI(Self, SourceLccNode, DestLccNode)
end;
{$ENDIF}

{$IFDEF TRACTION}
procedure TLccNodeManager.DoFunctionConfiguration(SourceLccNode, DestLccNode: TLccNode);
begin
  if Assigned(OnLccNodeFunctionConfiguration) then
    OnLccNodeFunctionConfiguration(Self, SourceLccNode, DestLccNode)
end;
{$ENDIF}

procedure TLccNodeManager.DoGetRootNodeClass( var RootNodeClass: TLccOwnedNodeClass);
begin
  RootNodeClass := TLccDefaultRootNode;
  if Assigned(OnLccGetRootNodeClass) then
    OnLccGetRootNodeClass(Self, RootNodeClass);
end;

procedure TLccNodeManager.DoInitializationComplete(SourceLccNode: TLccNode);
begin
  if Assigned(OnLccNodeInitializationComplete) then
    OnLccNodeInitializationComplete(Self, SourceLccNode);
end;

procedure TLccNodeManager.DoNodeIDChanged(LccNode: TLccNode);
begin
  if Assigned(NetworkTree) then
    NetworkTree.DoNodeIDChanged(LccNode);
  if Assigned(OnNodeIDChanged) then
    OnNodeIDChanged(Self, LccNode);
end;

procedure TLccNodeManager.DoOptionalInteractionRejected(SourceLccNode, DestLccNode: TLccNode);
begin
  if Assigned(OnLccNodeOptionalInteractionRejected) then
    OnLccNodeOptionalInteractionRejected(Self, SourceLccNode, DestLccNode);
end;

procedure TLccNodeManager.DoProducerIdentified(SourceLccNode: TLccNode; var Event: TEventID; State: TEventState);
begin
  if Assigned(NetworkTree) then
    NetworkTree.DoProducerIdentified(SourceLccNode, Event, State);
  if Assigned(OnLccNodeProducerIdentified) then
    OnLccNodeProducerIdentified(Self, SourceLccNode, Event, State);
end;

procedure TLccNodeManager.DoProtocolIdentifyReply(SourceLccNode, DestLccNode: TLccNode);
begin
  if Assigned(NetworkTree) then
    NetworkTree.DoProtocolIdentifyReply(SourceLccNode, DestLccNode);
  if Assigned(OnLccNodeProtocolIdentifyReply) then
    OnLccNodeProtocolIdentifyReply(Self, SourceLccNode, DestLccNode);
end;

procedure TLccNodeManager.DoRemoteButtonReply(SourceLccNode, DestLccNode: TLccNode);
begin
  if Assigned(OnLccNodeRemoteButtonReply) then
    OnLccNodeRemoteButtonReply(Self, SourceLccNode, DestLccNode);
end;

procedure TLccNodeManager.DoRequestMessageSend(Message: TLccMessage);
begin
  if Assigned(HardwareConnection) then
    HardwareConnection.SendMessage(Message);
  if Assigned(OnRequestMessageSend) then
    OnRequestMessageSend(Self, Message);
end;

procedure TLccNodeManager.DoSimpleNodeIdentReply(SourceLccNode, DestLccNode: TLccNode);
begin
  if Assigned(NetworkTree) then
    NetworkTree.DoSimpleNodeIdentReply(SourceLccNode, DestLccNode);
  if Assigned(OnLccNodeSimpleNodeIdentReply) then
    OnLccNodeSimpleNodeIdentReply(Self, SourceLccNode, DestLccNode);
end;

{$IFDEF TRACTION}
procedure TLccNodeManager.DoSimpleTrainNodeIdentReply(SourceLccNode,
  DestLccNode: TLccNode);
begin
  if Assigned(OnLccNodeSimpleTrainNodeIdentReply) then
    OnLccNodeSimpleTrainNodeIdentReply(Self, SourceLccNode, DestLccNode);
end;
{$ENDIF}

{$IFDEF TRACTION}
procedure TLccNodeManager.DoTractionControllerChangeNotify(SourceLccNode,
  DestLccNode: TLccNode; NewRequestingNode: TNodeID;
  NewRequestingNodeAlias: Word; var Allow: Boolean);
begin
  if Assigned(OnLccNodeTractionControllerChangeNotify) then
    OnLccNodeTractionControllerChangeNotify(Self, SourceLccNode, DestLccNode, NewRequestingNode, NewRequestingNodeAlias, Allow);
end;
{$ENDIF}

{$IFDEF TRACTION}
procedure TLccNodeManager.DoTractionProxyReplyAllocate(SourceLccNode,
  DestLccNode: TLccNode; LegacyTechnology: Byte; TrainID: Word;
  var TrainNode: TNodeID; TrainAlias: Word);
begin
  if Assigned(OnLccNodeTractionProxyReplyAllocate) then
    OnLccNodeTractionProxyReplyAllocate(Self, SourceLccNode, DestLccNode, LegacyTechnology, TrainID, TrainNode, TrainAlias);
end;
{$ENDIF}


{$IFDEF TRACTION}
procedure TLccNodeManager.DoTractionProxyReplyAttach(SourceLccNode,
  DestLccNode: TLccNode; ReplyCode: Byte);
begin
  if Assigned(OnLccNodeTractionProxyReplyAttach) then
    OnLccNodeTractionProxyReplyAttach(Self, SourceLccNode, DestLccNode, ReplyCode);
end;
{$ENDIF}

{$IFDEF TRACTION}
procedure TLccNodeManager.DoTractionProxyReplyManage(SourceLccNode,
  DestLccNode: TLccNode; ResultCode: Byte);
begin
  if Assigned(OnLccNodeTractionProxyReplyManage) then
    OnLccNodeTractionProxyReplyManage(Self, SourceLccNode, DestLccNode, ResultCode);
end;
{$ENDIF}

{$IFDEF TRACTION}
procedure TLccNodeManager.DoTractionReplyQuerySpeed(SourceLccNode,
  DestLccNode: TLccNode);
begin
  if Assigned(OnLccNodeTractionReplyQuerySpeed) then
    OnLccNodeTractionReplyQuerySpeed(Self, SourceLccNode, DestLccNode);
end;
{$ENDIF}

{$IFDEF TRACTION}
procedure TLccNodeManager.DoTractionReplyQueryFunction(SourceLccNode,
  DestLccNode: TLccNode);
begin
  if Assigned(OnLccNodeTractionReplyQueryFunction) then
    OnLccNodeTractionReplyQueryFunction(Self, SourceLccNode, DestLccNode);
end;
{$ENDIF}

{$IFDEF TRACTION}
procedure TLccNodeManager.DoTractionReplyControllerAssign(SourceLccNode,
  DestLccNode: TLccNode; ResultCode: Byte);
begin
  if Assigned(OnLccNodeTractionReplyControllerAssign) then
    OnLccNodeTractionReplyControllerAssign(Self, SourceLccNode, DestLccNode, ResultCode);
end;
{$ENDIF}

{$IFDEF TRACTION}
procedure TLccNodeManager.DoTractionReplyControllerQuery(SourceLccNode,
  DestLccNode: TLccNode; ActiveControllerNodeID: TNodeID;
  ActiveControllerAlias: Word);
begin
  if Assigned(OnLccNodeTractionReplyControllerQuery) then
    OnLccNodeTractionReplyControllerQuery(Self, SourceLccNode, DestLccNode, ActiveControllerNodeID, ActiveControllerAlias);
end;
{$ENDIF}

{$IFDEF TRACTION}
procedure TLccNodeManager.DoTractionReplyControllerChangeNotify(
  SourceLccNode, DestLccNode: TLccNode; ResultCode: Byte);
begin
  if Assigned(OnLccNodeTractionReplyControllerChangeNotify) then
    OnLccNodeTractionReplyControllerChangeNotify(Self, SourceLccNode, DestLccNode, ResultCode);
end;
{$ENDIF}

{$IFDEF TRACTION}
procedure TLccNodeManager.DoTractionReplyManage(SourceLccNode,
  DestLccNode: TLccNode; ResultCode: Byte);
begin
  if Assigned(OnLccNodeTractionReplyManage) then
    OnLccNodeTractionReplyManage(Self, SourceLccNode, DestLccNode, ResultCode);
end;
{$ENDIF}

procedure TLccNodeManager.DoVerifiedNodeID(SourceLccNode: TLccNode);
begin
  if Assigned(NetworkTree) then
    NetworkTree.DoVerifiedNodeID(SourceLccNode);
  if Assigned(OnLccNodeVerifiedNodeID) then
    OnLccNodeVerifiedNodeID(Self, SourceLccNode);
end;

function TLccNodeManager.FindSourceNode(LccMessage: TLccMessage; IncludeRoot: Boolean): TLccNode;
var
  i: Integer;
begin
  Result := nil;
  if IncludeRoot then
  begin
    if RootNode.IsNode(LccMessage, ntt_Source) then
    begin
      Result := RootNode;
      Exit;
    end;
  end;
  i := 0;     // Cheap, slow linear search for now
  while i < NodeList.Count do
  begin
    if Nodes[i].IsNode(LccMessage, ntt_Source) then
    begin
      Result := Nodes[i];
      Break;
    end;
    Inc(i);
  end;
end;

function TLccNodeManager.FindDestNode(LccMessage: TLccMessage; IncludeRoot: Boolean): TLccNode;
var
  i: Integer;
begin
  Result := nil;
  if IncludeRoot then
  begin
    if RootNode.IsNode(LccMessage, ntt_Dest) then
    begin
      Result := RootNode;
      Exit;
    end;
  end;
  i := 0;     // Cheap, slow linear search for now
  while i < NodeList.Count do
  begin
    if Nodes[i].IsNode(LccMessage, ntt_Dest) then
    begin
      Result := Nodes[i];
      Break;
    end;
    Inc(i);
  end;
end;

procedure TLccNodeManager.NodeIDStringToNodeID(ANodeIDStr: string; var ANodeID: TNodeID);
var
  TempStr: string;
  TempNodeID: QWord;
begin
  ANodeIDStr := Trim(ANodeIDStr);
  TempStr := StringReplace(ANodeIDStr, '0x', '', [rfReplaceAll, rfIgnoreCase]);
  TempStr := StringReplace(TempStr, '$', '', [rfReplaceAll, rfIgnoreCase]);
  try
    TempNodeID := StrToInt64('$' + TempStr);
    ANodeID[0] := DWord( TempNodeID and $0000000000FFFFFF);
    ANodeID[1] := DWord( (TempNodeID shr 24) and $0000000000FFFFFF);
  except
    ANodeID[0] := 0;
    ANodeID[1]  := 0;
  end;
end;

function TLccNodeManager.NodeIDToNodeIDStr(ANodeID: TNodeID): string;
begin
  Result := IntToHex(ANodeID[1], 6);
  Result := Result + IntToHex(ANodeID[0], 6);
end;

procedure TLccNodeManager.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if AComponent is TLccCdiParserBase then
  begin
     case Operation of
       opInsert :
           begin
             TLccCdiParserBase(AComponent).SetNodeManager(Self);
           end;
       opRemove :
           begin
             TLccCdiParserBase(AComponent).SetNodeManager(nil);
           end;
     end;
  end;

 case Operation of
   opInsert :
       begin
         if NetworkTree = nil then
           if AComponent = NetworkTree then
             NetworkTree := AComponent as TLccNetworkTree;
       end;
   opRemove :
       begin
         if AComponent = NetworkTree then
           NetworkTree := nil
       end;
   end;

end;

constructor TLccNodeManager.Create(AnOwner: TComponent);
begin
  inherited Create(AnOwner);
  FNodeList := TList.Create;
  FOwnedNodeList := TList.Create;
  FWorkerMessage := TLccMessage.Create;
  FUserMessage := TLccMessage.Create;
end;

destructor TLccNodeManager.Destroy;
begin
  Clear;
  ClearOwned;
  FreeAndNil(FNodeList);
  FreeAndNil(FWorkerMessage);
  FreeAndNil(FOwnedNodeList);
  FreeAndNil(FRootNode);
  FreeAndNil(FUserMessage);
  inherited Destroy;
end;

procedure TLccNodeManager.Clear;
var
  i: Integer;
begin
  try
    for i := 0 to FNodeList.Count - 1 do
      TObject( FNodeList[i]).Free;
  finally
    NodeList.Clear;
  end;
end;

procedure TLccNodeManager.ClearOwned;
var
  i: Integer;
begin
  try
    for i := 0 to FOwnedNodeList.Count - 1 do
      TObject( FOwnedNodeList[i]).Free;
  finally
    OwnedNodeList.Clear;
  end;
end;

function TLccNodeManager.CreateNodeBySourceMessage(LccMessage: TLccMessage): TLccNode;
begin
  Result := TLccNode.Create(Self);
  Result.OwnerManager := Self;
  Result.FAliasID := LccMessage.CAN.SourceAlias;
  Result.FNodeID[0] := LccMessage.SourceID[0];
  Result.FNodeID[1] := LccMessage.SourceID[1];
  NodeList.Add(Result);
end;

function TLccNodeManager.CreateNodeByDestMessage(LccMessage: TLccMessage): TLccNode;
begin
  Result := TLccNode.Create(Self);
  Result.OwnerManager := Self;
  Result.FAliasID := LccMessage.CAN.DestAlias;
  Result.FNodeID[0] := LccMessage.DestID[0];
  Result.FNodeID[1] := LccMessage.DestID[1];
  NodeList.Add(Result);
end;

function TLccNodeManager.CreateOwnedNode: TLccOwnedNode;
begin
  Result := TLccOwnedNode.Create(Self);
  Result.OwnerManager := Self;
  OwnedNodeList.Add(Result);
end;

function TLccNodeManager.EqualEventID(var Event1, Event2: TEventID): Boolean;
var
  i: Integer;
begin
  Result := True;
  i := 0;
  while (i < 8) and Result do
  begin
    if Event1[i] <> Event2[i] then
    begin
      Result := False;
      Break
    end;
    Inc(i);
  end;
end;

function TLccNodeManager.FindByGuiNode(GuiNode: TLccGuiNode): TLccNode;
var
  i: Integer;
  LccNode: TLccNode;
begin
  Result := nil;
  if GuiNode = nil then Exit;
  for i := 0 to NodeList.Count - 1 do
  begin
    LccNode := TLccNode( NodeList[i]);
    if LccNode.LccGuiNode = GuiNode then
    begin
      Result := LccNode;
      Break
    end;
  end;
end;

function TLccNodeManager.FindNode(ANodeID: TNodeID; ANodeAlias: Word): TLccNode;
var
  i: Integer;
  LccNode: TLccNode;
begin
  Result := nil;
  for i := 0 to NodeList.Count - 1 do
  begin
    LccNode := TLccNode( NodeList[i]);
    if EqualNodeID(ANodeID, LccNode.NodeID, False) or (ANodeAlias = LccNode.AliasID) then
    begin
      Result := LccNode;
      Break
    end;
  end;
end;

function TLccNodeManager.FindOwnedDestNode(LccMessage: TLccMessage): TLccOwnedNode;
var
  i: Integer;
begin
  Result := nil;
  if RootNode.IsNode(LccMessage, ntt_Dest) then
    Result := RootNode
  else begin
    i := 0;     // Cheap, slow linear search for now
    while i < OwnedNodeList.Count do
    begin
      if OwnedNodes[i].IsNode(LccMessage, ntt_Dest) then
      begin
        Result := OwnedNodes[i];
        Break;
      end
    end;
  end;
end;

function TLccNodeManager.FindOwnedSourceNode(LccMessage: TLccMessage): TLccOwnedNode;
var
  i: Integer;
begin
  Result := nil;
  if RootNode.IsNode(LccMessage, ntt_Source) then
    Result := RootNode
  else begin
    i := 0;     // Cheap, slow linear search for now
    while i < OwnedNodeList.Count do
    begin
      if OwnedNodes[i].IsNode(LccMessage, ntt_Source) then
      begin
        Result := OwnedNodes[i];
        Break;
      end
    end;
  end;
end;

function TLccNodeManager.IsManagerNode(LccMessage: TLccMessage; TestType: TIsNodeTestType): Boolean;
begin
  Result := False;
  if Assigned(RootNode) then
  begin
    if TestType = ntt_Dest then
    begin
      if LccMessage.HasDestNodeID and not NullNodeID(RootNode.NodeID) then
        Result := ((RootNode.NodeID[0] = LccMessage.DestID[0]) and (RootNode.NodeID[1] = LccMessage.DestID[1])) or (RootNode.AliasID = LccMessage.CAN.DestAlias)
      else
      if (RootNode.AliasID <> 0) and (LccMessage.CAN.DestAlias <> 0) then
        Result := RootNode.AliasID = LccMessage.CAN.DestAlias
    end else
    if TestType = ntt_Source then
    begin
      if LccMessage.HasSourceNodeID and not NullNodeID(RootNode.NodeID) then
        Result := ((RootNode.NodeID[0] = LccMessage.SourceID[0]) and (RootNode.NodeID[1] = LccMessage.SourceID[1])) or (RootNode.AliasID = LccMessage.CAN.SourceAlias)
      else
      if (RootNode.AliasID <> 0) and (LccMessage.CAN.SourceAlias <> 0) then
        Result := RootNode.AliasID = LccMessage.CAN.SourceAlias
    end;
  end
end;

procedure TLccNodeManager.Loaded;
var
  RootNodeClass: TLccOwnedNodeClass;
begin
  inherited Loaded;
  RootNodeClass := nil;
  DoGetRootNodeClass(RootNodeClass);
  FRootNode := RootNodeClass.Create(Self);
  FRootNode.OwnerManager := Self;
  DoCreateLccNode(FRootNode);
end;

function TLccNodeManager.ProcessMessage(LccMessage: TLccMessage): Boolean;
var
  LccSourceNode: TLccNode;
  LccOwnedNode: TLccOwnedNode;
  i: Integer;
  MessageHandled: Boolean;
begin
  Result := True;
  if Enabled then
  begin
    MessageHandled := False;
    // First see if we have the node on the network that sent this message and allow
    // the NodeList to update those objects that are images of those nodes.
    LccSourceNode := FindSourceNode(LccMessage, True);
    if not Assigned(LccSourceNode) and (RootNode.Initialized) then
    begin                                                                         // We don't have an image of this node in our database
      LccSourceNode := CreateNodeBySourceMessage(LccMessage);
      DoCreateLccNode(LccSourceNode);
      MessageHandled := LccSourceNode.ProcessMessage(LccMessage);
      if LccMessage.MTI = MTI_VERIFIED_NODE_ID_NUMBER then
      begin
        if AutoInterrogateDiscoveredNodes then
        begin
          // Most likely reply from booting up so we need to get the events
          WorkerMessage.LoadIdentifyEventsAddressed(RootNode.NodeID, RootNode.AliasID, LccSourceNode.NodeID, LccSourceNode.AliasID);
          DoRequestMessageSend(WorkerMessage);
        end;
      end else
      if LccMessage.MTI = MTI_INITIALIZATION_COMPLETE then
      begin
        // Events will be coming as part of the initialization sequence
      end else
      begin
        if AutoInterrogateDiscoveredNodes and not (LccMessage.IsCAN) then
        begin
          // Found a node some other way so need to get it information (NodeID and Events)
          WorkerMessage.LoadVerifyNodeIDAddressed(RootNode.NodeID, RootNode.AliasID, LccSourceNode.NodeID, LccSourceNode.AliasID);
          DoRequestMessageSend(WorkerMessage);
          WorkerMessage.LoadIdentifyEventsAddressed(RootNode.NodeID, RootNode.AliasID, LccSourceNode.NodeID, LccSourceNode.AliasID);
          DoRequestMessageSend(WorkerMessage);
        end
      end;
    end else
    begin
      if Assigned(LccSourceNode) then
        MessageHandled := LccSourceNode.ProcessMessage(LccMessage);
    end;

    // Now handle messages that are directed to our internally created and mananged nodes
    if not MessageHandled then
    begin
      if LccMessage.HasDestination then
      begin
        LccOwnedNode := FindOwnedDestNode(LccMessage);
        if Assigned(LccOwnedNode) then
          LccOwnedNode.ProcessMessage(LccMessage)
        else begin
          LccOwnedNode := FindOwnedSourceNode(LccMessage);
          if Assigned(LccOwnedNode) then
            LccOwnedNode.ProcessMessage(LccMessage)   // this will throw an error and reallocate the alias
        end;
      end else
      begin
        RootNode.ProcessMessage(LccMessage);
        for i := 0 to OwnedNodeList.Count - 1 do
          TLccOwnedNode( OwnedNodeList[i]).ProcessMessage(LccMessage);
      end;
    end;
  end
end;

procedure TLccNodeManager.SendLccMessage(LccMessage: TLccMessage);
begin
  DoRequestMessageSend(LccMessage);
end;

{$IFDEF TRACTION}
{ TSimpleTrainNodeInfo }

function TSimpleTrainNodeInfo.ProcessMessage(LccMessage: TLccMessage;
  Traction: TTraction): Boolean;

    function NextString(AStrPtr: PChar): PChar;
    begin
      Result := AStrPtr;
      while Result^ <> #0 do
        Inc(Result);
      Inc(Result);
    end;

var
  StrPtr: PChar;
begin
  Result := True;
  StrPtr := @LccMessage.DataArray[0];

  FVersion := Ord( StrPtr^);
  Inc(StrPtr);
  FRoadname := StrPtr;
  StrPtr := NextString(StrPtr);
  FTrainClass := StrPtr;
  StrPtr := NextString(StrPtr);
  FRoadNumber := StrPtr;
  StrPtr := NextString(StrPtr);
  FTrainName := StrPtr;
  StrPtr := NextString(StrPtr);
  FManufacturer := StrPtr;
  StrPtr := NextString(StrPtr);
  FOwner := StrPtr;
  StrPtr := NextString(StrPtr);
  Traction.LegacyTechnology := Ord(StrPtr^);
  Inc(StrPtr);
  Traction.LegacyTrainID := Ord( StrPtr^) shl 8;
  Inc(StrPtr);
  Traction.LegacyTrainID := Ord(StrPtr^) or Traction.LegacyTrainID;
  Inc(StrPtr);
  if Ord( StrPtr^) > 0 then
    Traction.LegacyTrainID := Traction.LegacyTrainID or $C000;
  Inc(StrPtr);
  case Ord(StrPtr^) of
    0 : Traction.LegacySpeedSteps := 14;
    1 : Traction.LegacySpeedSteps := 28;
    2 : Traction.LegacySpeedSteps := 128
  else
    Traction.LegacySpeedSteps := 28;
  end;
  Valid := True;
end;
{$ENDIF}

{ TSimpleNodeInfo }

function TSimpleNodeInfo.GetPackedFormat: TSimpleNodeInfoPacked;
const
  NULL_COUNT = 6;
  VERSION_COUNT = 2;
var
  iArray, i: Integer;
begin
  i :=  Length(Manufacturer) + Length(Model) + Length(HardwareVersion) + Length(SoftwareVersion) + Length(UserName) + Length(UserDescription);
  i := i + NULL_COUNT + VERSION_COUNT;
  SetLength(FPackedInfo, i);
  iArray := 0;

  FPackedInfo[iArray] := Version;      // 4 Items follow
  Inc(iArray);
  StringToNullArray(Manufacturer, FPackedInfo, iArray);
  StringToNullArray(Model, FPackedInfo, iArray);
  StringToNullArray(HardwareVersion, FPackedInfo, iArray);
  StringToNullArray(SoftwareVersion, FPackedInfo, iArray);

  FPackedInfo[iArray] := UserVersion;  // 2 items follow
  Inc(iArray);
  StringToNullArray(UserName, FPackedInfo, iArray);
  StringToNullArray(UserDescription, FPackedInfo, iArray);

  Result := FPackedInfo;
end;

function TSimpleNodeInfo.GetUserDescription: string;
begin
  Result := FUserDescription;
  if Owner is TLccOwnedNode then
    Result := (Owner as TLccOwnedNode).Configuration.ReadAsString(64);
end;

function TSimpleNodeInfo.GetUserName: string;
begin
  Result := FUserName;
  if Owner is TLccOwnedNode then
    Result := (Owner as TLccOwnedNode).Configuration.ReadAsString(1);
end;

function TSimpleNodeInfo.LoadFromXml(CdiFilePath: string): Boolean;
var
  XMLDoc: TXMLDocument;
  CdiNode, IdentificationNode, ChildNode: TDOMNode;
begin
  Result := False;
  if FileExists(CdiFilePath) then
  begin
    try
      ReadXMLFile(XmlDoc, CdiFilePath);
      if Assigned(XmlDoc) then
      begin
        CdiNode := XmlDoc.FindNode('cdi');
        if Assigned(CdiNode) then
        begin
          IdentificationNode := CdiNode.FindNode('identification');
          if Assigned(IdentificationNode) then
          begin
             Version := 1;
             ChildNode := IdentificationNode.FindNode('manufacturer');
             if Assigned(ChildNode) then FManufacturer := ChildNode.FirstChild.NodeValue else Exit;
             ChildNode := IdentificationNode.FindNode('model');
             if Assigned(ChildNode) then FModel := ChildNode.FirstChild.NodeValue else Exit;
             ChildNode := IdentificationNode.FindNode('hardwareVersion');
             if Assigned(ChildNode) then FHardwareVersion := ChildNode.FirstChild.NodeValue else Exit;
             ChildNode := IdentificationNode.FindNode('softwareVersion');
             if Assigned(ChildNode) then FSoftwareVersion := ChildNode.FirstChild.NodeValue else Exit;
             UserVersion := 1;
             Result := True;
          end;
        end;
      end;
    except
      // Quiet fail
    end;
  end;
end;

function TSimpleNodeInfo.ProcessMessage(LccMessage: TLccMessage): Boolean;

  function NextString(AStrPtr: PChar): PChar;
  begin
    Result := AStrPtr;
    while Result^ <> #0 do
      Inc(Result);
    Inc(Result);
  end;

var
  StrPtr: PChar;
begin
  Result := True;
  StrPtr := @LccMessage.DataArray[0];
  FVersion := Ord(StrPtr^);
  Inc(StrPtr);
  FManufacturer := StrPtr;
  StrPtr := NextString(StrPtr);
  FModel := StrPtr;
  StrPtr := NextString(StrPtr);
  FHardwareVersion := StrPtr;
  StrPtr := NextString(StrPtr);
  FSoftwareVersion := StrPtr;
  StrPtr := NextString(StrPtr);
  FUserVersion := Ord(StrPtr^);
  Inc(StrPtr);
  FUserName := StrPtr;
  StrPtr := NextString(StrPtr);
  FUserDescription := StrPtr;
  Valid := True;
end;

{ TSimpleNodeInfo }

{function TSimpleNodeInfo.GetPackedFormat: TSimpleNodeInfoPacked;
begin

end;

 function TSimpleNodeInfo.ProcessMessage(LccMessage: TLccMessage): Boolean;
begin

end;

TProtocolSupport }

procedure TProtocolSupport.DecodeFlags;
begin
  if Length(Flags) > 0 then
  begin
    FACDI := Flags[0] and PIP_ABBREVIATED_CDI <> 0;
    FCDI := Flags[0] and PIP_CDI <> 0;
    FDatagram := Flags[0] and PIP_DATAGRAM <> 0;
    FDisplay := Flags[0] and PIP_DISPLAY <> 0;
    FEventExchange := Flags[0] and PIP_EVENT_EXCHANGE <> 0;
    {$IFDEF TRACTION}
    FFDI := Flags[0] and PIP_FDI <> 0;
    FFunctionConfiguration := Flags[0] and PIP_FUNCTION_CONFIGURATION <> 0;
    {$ENDIF}
    FIdentification := Flags[0] and PIP_PIP <> 0;
    FMemConfig := Flags[0] and PIP_MEMORY_CONFIG <> 0;
    FRemoteButton := Flags[0] and PIP_REMOTE_BUTTON <> 0;
    FReservation := Flags[0] and PIP_RESERVATION <> 0;
    FSimpleNodeInfo := Flags[0] and PIP_SIMPLE_NODE_INFO <> 0;
    {$IFDEF TRACTION}
    FSimpleTrainNodeInfo := Flags[0] and PIP_SIMPLE_TRAIN_NODE_INFO <> 0;
    {$ENDIF}
    FStream := Flags[0] and PIP_STREAM <> 0;
    FTeach_Learn := Flags[0] and PIP_TEACH_LEARN <> 0;
    {$IFDEF TRACTION}
    FTractionControl := Flags[0] and PIP_TRACTION <> 0;
    FTractionProxy := Flags[0] and PIP_TRACTION_PROXY <> 0;
    {$ENDIF}
    Valid := True;
  end;
end;

function TProtocolSupport.EncodeFlags: QWord;
begin
  Result := 0;
  if ACDI then Result := Result or PIP_ABBREVIATED_CDI;
  if CDI then Result := Result or PIP_CDI;
  if Datagram then Result := Result or PIP_DATAGRAM;
  if Display then Result := Result or PIP_DISPLAY;
  if EventExchange then Result := Result or PIP_EVENT_EXCHANGE;
  {$IFDEF TRACTION}
  if FDI then Result := Result or PIP_FDI;
  if FunctionConfiguration then Result := Result or PIP_FUNCTION_CONFIGURATION;
  {$ENDIF}
  if Identification then Result := Result or PIP_PIP;
  if MemConfig then Result := Result or PIP_MEMORY_CONFIG;
  if RemoteButton then Result := Result or PIP_REMOTE_BUTTON;
  if Reservation then Result := Result or PIP_RESERVATION;
  if SimpleNodeInfo then Result := Result or PIP_SIMPLE_NODE_INFO;
  if Stream then Result := Result or PIP_STREAM;
  if Teach_Learn then Result := Result or PIP_TEACH_LEARN;
  {$IFDEF TRACTION}
  if SimpleTrainNodeInfo then Result := Result or PIP_SIMPLE_TRAIN_NODE_INFO;
  if TractionControl then Result := Result or PIP_TRACTION;
  if TractionProxy then Result := Result or PIP_TRACTION_PROXY;
  {$ENDIF}
end;

function TProtocolSupport.ProcessMessage(LccMessage: TLccMessage): Boolean;
var
  i, FlagBlocks, Offset: Integer;
begin
  Result := True;
  FlagBlocks := LccMessage.DataCount div 6;
  SetLength(Flags, FlagBlocks);
  Offset := 0;
  for i := 0 to FlagBlocks - 1 do
  begin
    Flags[i] := LccMessage.ExtractDataBytesAsInt(Offset, 5);     // Protocol uses 6 byte chunks due to needing to use 2 in the CAN for the destination
    Offset := Offset + 6;
  end;
  DecodeFlags;
end;

{ TStreamBasedProtocol }

procedure TStreamBasedProtocol.SetValid(AValue: Boolean);
begin
  inherited SetValid(AValue);
  if not AValue then
  begin
    AStream.Size := 0;
    InProcessAddress := 0;
  end
end;

procedure TStreamBasedProtocol.WriteRequest(LccMessage: TLccMessage);
begin

end;

constructor TStreamBasedProtocol.Create(AnOwner: TComponent; AnAddressSpace: Byte);
begin
  inherited Create(AnOwner);
  FStream := TMemoryStream.Create;
  FAddressSpace := AnAddressSpace;
end;

destructor TStreamBasedProtocol.Destroy;
begin
  FreeAndNil(FStream);
  inherited Destroy;
end;

procedure TStreamBasedProtocol.DoLoadComplete(LccMessage: TLccMessage);
begin

end;

procedure TStreamBasedProtocol.LoadReply(LccMessage: TLccMessage; OutMessage: TLccMessage);
var
  i: Integer;
  iStart, ReadCount: Integer;
  AByte: Byte;
begin
  // Assumption is this is a datagram message
  if LccMessage.DataArrayIndexer[1] and $03 = 0 then
    iStart := 7
  else
    iStart := 6;
  ReadCount := LccMessage.DataArrayIndexer[iStart];
  OutMessage.DataArrayIndexer[0] := LccMessage.DataArrayIndexer[0];
  OutMessage.DataArrayIndexer[1] := LccMessage.DataArrayIndexer[1] or $10;   // Make it a reply
  OutMessage.DataArrayIndexer[2] := LccMessage.DataArrayIndexer[2];    // Copy the address
  OutMessage.DataArrayIndexer[3] := LccMessage.DataArrayIndexer[3];
  OutMessage.DataArrayIndexer[4] := LccMessage.DataArrayIndexer[4];
  OutMessage.DataArrayIndexer[5] := LccMessage.DataArrayIndexer[5];

  if AStream.Size = 0 then
  begin
    OutMessage.DataCount := iStart + 1;
    OutMessage.DataArrayIndexer[iStart] := Ord(#0);
  end else
  begin
    AStream.Position := LccMessage.ExtractDataBytesAsInt(2, 5);
    i := 0;
    while (AStream.Position < AStream.Size) and (i < ReadCount) do
    begin
      AByte := 0;
      AStream.Read(AByte, 1);
      OutMessage.DataArrayIndexer[iStart + i] := AByte;
      Inc(i);
    end;
    OutMessage.DataCount := iStart + i;

    if AStream.Position = AStream.Size then
    begin
      OutMessage.DataArrayIndexer[OutMessage.DataCount] := Ord(#0);
      OutMessage.DataCount := OutMessage.DataCount + 1
    end;
  end;
  OutMessage.UserValid := True;
end;

function TStreamBasedProtocol.ProcessMessage(LccMessage: TLccMessage): Boolean;
var
  NullFound: Boolean;
  i: Integer;
  iStart: Integer;
  AByte: Byte;
begin
  Result := True;
  if not Valid then
  begin
    NullFound := False;
    if LccMessage.DataArrayIndexer[1] and $03 = 0 then
      iStart := 7
    else
      iStart := 6;
    for i := iStart to LccMessage.DataCount - 1 do
    begin
      NullFound := LccMessage.DataArrayIndexer[i] = Ord(#0);
      AByte := LccMessage.DataArrayIndexer[i];
      AStream.WriteBuffer(AByte, 1);
      if NullFound then
        Break
    end;

    if NullFound then
    begin
      AStream.Position := 0;
      FValid := True;
      DoLoadComplete(LccMessage);
    end else
    begin
      WorkerMessage.IsCAN := False;
      WorkerMessage.SourceID := LccMessage.DestID;
      WorkerMessage.CAN.SourceAlias := LccMessage.CAN.DestAlias;
      WorkerMessage.DestID := LccMessage.SourceID;
      WorkerMessage.CAN.DestAlias := LccMessage.CAN.SourceAlias;
      WorkerMessage.DataCount := 0;
      WorkerMessage.DataArrayIndexer[0] := DATAGRAM_PROTOCOL_CONFIGURATION;
      WorkerMessage.DataArrayIndexer[1] := MCP_READ;
      InProcessAddress := InProcessAddress + 64 {- iStart};
      WorkerMessage.InsertDWordAsDataBytes(InProcessAddress, 2);
      WorkerMessage.DataArrayIndexer[6] := AddressSpace;
      WorkerMessage.DataArrayIndexer[7] := 64;                     // Read until the end.....
      WorkerMessage.DataCount := 8;
      WorkerMessage.MTI := MTI_DATAGRAM;
      OwnerManager.DoRequestMessageSend(WorkerMessage);
    end;
  end;
end;

{ TLccNode }

procedure TLccNode.SetOwnerManager(AValue: TLccNodeManager);
begin
  inherited SetOwnerManager(AValue);
  ProtocolSupport.OwnerManager := AValue;
  SimpleNodeInfo.OwnerManager := AValue;
  {$IFDEF TRACTION}
  FDI.OwnerManager := AValue;
  FunctionConfiguration.OwnerManager := AValue;
  SimpleTrainNodeInfo.OwnerManager := AValue;
  {$ENDIF}
  CDI.OwnerManager := AValue;
  ConfigurationMem.OwnerManager := AValue;
  EventsProduced.OwnerManager := AValue;
  EventsConsumed.OwnerManager := AValue;
  ConfigMemAddressSpaceInfo.OwnerManager := AValue;
  ConfigMemOptions.OwnerManager := AValue;
end;

function TLccNode.GetNodeIDStr: string;
begin
  Result := IntToHex(NodeID[1], 6);
  Result := Result + IntToHex(NodeID[0], 6);
  Result := '0x' + Result
end;

function TLccNode.GetAliasIDStr: string;
begin
  Result := '0x' + IntToHex(FAliasID, 4);
end;

function TLccNode.ExtractAddressSpace(LccMessage: TLccMessage): Byte;
begin
  Result := 0;
  case LccMessage.DataArrayIndexer[1] and $03 of
    0 : Result := LccMessage.DataArrayIndexer[6];
    1 : Result := MSI_CONFIG;
    2 : Result := MSI_ALL;
    3 : Result := MSI_CDI;
  end;
end;

constructor TLccNode.Create(AnOwner: TComponent);
begin
  inherited Create(AnOwner);
  FProtocolSupport := TProtocolSupport.Create(Self);
  FSimpleNodeInfo := TSimpleNodeInfo.Create(Self);
  FCDI := TCDI.Create(Self, MSI_CDI);
  {$IFDEF TRACTION}
  FSimpleTrainNodeInfo := TSimpleTrainNodeInfo.Create(Self);
  FFDI := TFDI.Create(Self, MSI_FDI);
  FTraction := TTraction.Create(Self);
  FFunctionConfiguration := TFunctionConfiguration.Create(Self);
  {$ENDIF}
  FConfigurationMem := TConfigurationMemory.Create(Self);
  FiStartupSequence := 0;
  FEventsConsumed := TLccEvents.Create(Self);
  FEventsProduced := TLccEvents.Create(Self);
  FConfigMemOptions := TConfigurationMemOptions.Create(Self);
  FConfigMemAddressSpaceInfo := TConfigMemAddressSpaceInfo.Create(Self);
end;

destructor TLccNode.Destroy;
begin
  FreeAndNil(FProtocolSupport);
  FreeAndNil(FSimpleNodeInfo);
  {$IFDEF TRACTION}
  FreeAndNil(FSimpleTrainNodeInfo);
  FreeAndNil(FFDI);
  FreeAndNil(FTraction);
  FreeAndNil(FFunctionConfiguration);
  {$ENDIF}
  FreeAndNil(FCDI);
  FreeAndNil(FConfigurationMem);
  FreeAndNil(FEventsConsumed);
  FreeAndNil(FEventsProduced);
  FreeAndNil(FConfigMemOptions);
  FreeAndNil(FConfigMemAddressSpaceInfo);
  if Assigned(OwnerManager) then
    OwnerManager.DoDestroyLccNode(Self);
  inherited;
end;

function TLccNode.IsNode(LccMessage: TLccMessage; TestType: TIsNodeTestType): Boolean;
begin
  Result := False;
  if TestType = ntt_Dest then
  begin
    if LccMessage.HasDestNodeID and not NullNodeID(NodeID) then
      Result := ((NodeID[0] = LccMessage.DestID[0]) and (NodeID[1] = LccMessage.DestID[1])) or (AliasID = LccMessage.CAN.DestAlias)
    else
    if (AliasID <> 0) and (LccMessage.CAN.DestAlias <> 0) then
      Result := AliasID = LccMessage.CAN.DestAlias
  end else
  if TestType = ntt_Source then
  begin
    if LccMessage.HasSourceNodeID and not NullNodeID(NodeID) then
      Result := ((NodeID[0] = LccMessage.SourceID[0]) and (NodeID[1] = LccMessage.SourceID[1])) or (AliasID = LccMessage.CAN.SourceAlias)
    else
    if (AliasID <> 0) and (LccMessage.CAN.SourceAlias <> 0) then
      Result := AliasID = LccMessage.CAN.SourceAlias
  end;
end;

function TLccNode.ProcessMessage(LccMessage: TLccMessage): Boolean;
var
  ANodeID: TNodeID;
  Allow: Boolean;
  LccDestNode: TLccNode;
  EventPtr: PEventID;
begin
  Result := False;
  ANodeID[0] := 0;
  ANodeID[1] := 0;
  LccDestNode := nil;

  if Assigned(OwnerManager) then
  begin
    if LccMessage.HasDestination then
    begin
      LccDestNode := OwnerManager.FindDestNode(LccMessage, True);
      if not Assigned(LccDestNode) then
      begin
        LccDestNode := OwnerManager.CreateNodeByDestMessage(LccMessage);
        if Assigned(OwnerManager) and OwnerManager.AutoInterrogateDiscoveredNodes and not LccMessage.IsCAN then  // Have other nodes send out Verified
        begin
          WorkerMessage.LoadVerifyNodeIDAddressed(NodeID, AliasID, LccDestNode.NodeID, LccDestNode.AliasID);
          OwnerManager.DoRequestMessageSend(WorkerMessage);
        end;
      end;
    end;
  end;

  if LccMessage.IsCAN then
  begin

  end else
  begin
    case LccMessage.MTI of
      MTI_INITIALIZATION_COMPLETE :
          begin
            if Assigned(OwnerManager) then
            begin
              FAliasID := LccMessage.CAN.SourceAlias;
              LccMessage.ExtractDataBytesAsNodeID(0, FNodeID);
              OwnerManager.DoInitializationComplete(Self);
              Result := True;
            end;
          end;
      MTI_PROTOCOL_SUPPORT_REPLY :
          begin
            ProtocolSupport.ProcessMessage(LccMessage);
            if Assigned(OwnerManager) then
              OwnerManager.DoProtocolIdentifyReply(Self, LccDestNode);
            Result := True;
          end;
      MTI_VERIFY_NODE_ID_NUMBER :
          begin
          end;
      MTI_VERIFY_NODE_ID_NUMBER_DEST :
          begin
          end;
      MTI_VERIFIED_NODE_ID_NUMBER :
          begin
            FAliasID := LccMessage.CAN.SourceAlias;
            LccMessage.ExtractDataBytesAsNodeID(0, FNodeID);
            if Assigned(OwnerManager) then
              OwnerManager.DoVerifiedNodeID(Self);
            Result := True;
          end;
      MTI_SIMPLE_NODE_INFO_REPLY  :
          begin
            Inc(TotalSNIPMessages);
            SimpleNodeInfo.ProcessMessage(LccMessage);
            if Assigned(OwnerManager) then
              OwnerManager.DoSimpleNodeIdentReply(Self, LccDestNode);
            Result := True;
          end;
      {$IFDEF TRACTION}
      MTI_SIMPLE_TRAIN_INFO_REPLY :
          begin
            Inc(TotalSTNIPMessage);
            SimpleTrainNodeInfo.ProcessMessage(LccMessage, Traction);
            if Assigned(OwnerManager) then
              OwnerManager.DoSimpleTrainNodeIdentReply(Self, LccDestNode);
            Result := True;
          end;
      {$ENDIF}
      MTI_PRODUCER_IDENTIFIED_SET :
          begin
            EventPtr := LccMessage.ExtractDataBytesAsEventID(0);
            EventsProduced.Add(EventPtr^, evs_Valid);
            if Assigned(OwnerManager) then
              OwnerManager.DoProducerIdentified(Self, EventPtr^ , evs_Valid);
            Result := True;
          end;
      MTI_PRODUCER_IDENTIFIED_CLEAR :
          begin
            EventPtr := LccMessage.ExtractDataBytesAsEventID(0);
            EventsProduced.Add(EventPtr^, evs_InValid);
            if Assigned(OwnerManager) then
              OwnerManager.DoProducerIdentified(Self, EventPtr^, evs_InValid);
            Result := True;
          end;
      MTI_PRODUCER_IDENTIFIED_UNKNOWN :
          begin
            EventPtr := LccMessage.ExtractDataBytesAsEventID(0);
            EventsProduced.Add(EventPtr^, evs_Unknown);
            if Assigned(OwnerManager) then
              OwnerManager.DoProducerIdentified(Self, EventPtr^, evs_Unknown);
            Result := True;
          end;
      MTI_CONSUMER_IDENTIFIED_SET :
          begin
            EventPtr := LccMessage.ExtractDataBytesAsEventID(0);
            EventsConsumed.Add(EventPtr^, evs_Valid);
            if Assigned(OwnerManager) then
              OwnerManager.DoConsumerIdentified(Self, EventPtr^, evs_Valid);
            Result := True;
          end;
      MTI_CONSUMER_IDENTIFIED_CLEAR :
          begin
            EventPtr := LccMessage.ExtractDataBytesAsEventID(0);
            EventsConsumed.Add(EventPtr^, evs_InValid);
            if Assigned(OwnerManager) then
              OwnerManager.DoConsumerIdentified(Self, EventPtr^, evs_InValid);
            Result := True;
          end;
      MTI_CONSUMER_IDENTIFIED_UNKNOWN :
          begin
            EventPtr := LccMessage.ExtractDataBytesAsEventID(0);
            EventsConsumed.Add(EventPtr^, evs_Unknown);
            if Assigned(OwnerManager) then
              OwnerManager.DoConsumerIdentified(Self, EventPtr^, evs_Unknown);
            Result := True;
          end;
      {$IFDEF TRACTION}
      MTI_TRACTION_PROTOCOL :
          begin
            if Assigned(OwnerManager) then
            begin
              case LccMessage.DataArrayIndexer[0] of
                TRACTION_CONTROLLER_CONFIG :
                    begin
                      case LccMessage.DataArrayIndexer[1] of
                          TRACTION_CONTROLLER_CONFIG_NOTIFY :
                            begin
                              Allow := True;
                              OwnerManager.DoTractionControllerChangeNotify(Self, LccDestNode, LccMessage.ExtractDataBytesAsNodeID(3, ANodeID)^, LccMessage.ExtractDataBytesAsInt(9, 10), Allow);
                              WorkerMessage.LoadTractionControllerChangeNotifyReply(LccMessage.DestID, LccMessage.CAN.DestAlias, LccMessage.SourceID, LccMessage.CAN.SourceAlias, Allow);
                              OwnerManager.DoRequestMessageSend(WorkerMessage);
                              Result := True;
                            end;
                      end;
                    end;
              end
            end
          end;
      MTI_TRACTION_REPLY :
          begin
            ANodeID := NULL_NODE_ID;
            Traction.ProcessMessage(LccMessage);
            if Assigned(OwnerManager) then
            begin
              case LccMessage.DataArrayIndexer[0] of
                TRACTION_QUERY_SPEED : OwnerManager.DoTractionReplyQuerySpeed(Self, LccDestNode);
                TRACTION_QUERY_FUNCTION : OwnerManager.DoTractionReplyQueryFunction(Self, LccDestNode);
                TRACTION_CONTROLLER_CONFIG :
                    begin
                      case LccMessage.DataArrayIndexer[1] of
                        TRACTION_CONTROLLER_CONFIG_ASSIGN :
                            begin
                              OwnerManager.DoTractionReplyControllerAssign(Self, LccDestNode, LccMessage.DataArrayIndexer[2]);
                              Result := True;
                            end;
                        TRACTION_CONTROLLER_CONFIG_QUERY  :
                            begin
                              if LccMessage.DataArrayIndexer[2] and TRACTION_FLAGS_ALIAS_INCLUDED <> 0 then
                                OwnerManager.DoTractionReplyControllerQuery(Self, LccDestNode, LccMessage.ExtractDataBytesAsNodeID(3, ANodeID)^, LccMessage.ExtractDataBytesAsInt(9, 10))
                              else
                                OwnerManager.DoTractionReplyControllerQuery(Self, LccDestNode, LccMessage.ExtractDataBytesAsNodeID(3, ANodeID)^, 0);
                              Result := True;
                            end;
                        TRACTION_CONTROLLER_CONFIG_NOTIFY :
                            begin
                              OwnerManager.DoTractionReplyControllerChangeNotify(Self, LccDestNode, LccMessage.DataArrayIndexer[2]);
                              Result := True;
                            end;
                      end;
                    end;
                TRACTION_MANAGE :
                    begin
                      OwnerManager.DoTractionReplyManage(Self, LccDestNode, LccMessage.DataArrayIndexer[2]);
                      Result := True;
                    end;
            end;
          end;
      MTI_TRACTION_PROXY_REPLY :
          begin
            if Assigned(OwnerManager) then
            begin
              case LccMessage.DataArrayIndexer[0] of
                TRACTION_PROXY_MANAGE   :
                    begin
                      OwnerManager.DoTractionProxyReplyManage(Self, LccDestNode, LccMessage.DataArrayIndexer[2]);
                      Result := True;
                    end;
                TRACTION_PROXY_ALLOCATE :
                    begin
                      if LccMessage.DataArrayIndexer[1] and TRACTION_FLAGS_ALIAS_INCLUDED <> 0 then
                        OwnerManager.DoTractionProxyReplyAllocate(Self, LccDestNode, LccMessage.DataArrayIndexer[1], LccMessage.ExtractDataBytesAsInt(3, 4), LccMessage.ExtractDataBytesAsNodeID(5, ANodeID)^, LccMessage.ExtractDataBytesAsInt(11, 12))
                      else
                        OwnerManager.DoTractionProxyReplyAllocate(Self, LccDestNode, LccMessage.DataArrayIndexer[1], LccMessage.ExtractDataBytesAsInt(3, 4), LccMessage.ExtractDataBytesAsNodeID(5, ANodeID)^, 0);
                      Result := True;
                    end;
                TRACTION_PROXY_ATTACH   :
                    begin
                      OwnerManager.DoTractionProxyReplyAttach(Self, LccDestNode, LccMessage.DataArrayIndexer[1]);
                      Result := True;
                    end;
                else begin
                  // Something is broken but don't allow the Reservation to be stuck Reserved, Releasing it will not hurt
                    WorkerMessage.LoadTractionProxyManage(LccMessage.DestID, LccMessage.CAN.DestAlias, LccMessage.SourceID, LccMessage.CAN.SourceAlias, False);
                    OwnerManager.DoRequestMessageSend(WorkerMessage);
                    Result := True;
                  end
                end; // Case
              end;
            end;
        {$ENDIF}
        MTI_DATAGRAM :
            begin
              // Only Ack if we accept the datagram
       ///       WorkerMessage.LoadDatagramAck(LccMessage.DestID, LccMessage.CAN.DestAlias, LccMessage.SourceID, LccMessage.CAN.SourceAlias, True);
       //       OwnerManager.DoRequestMessageSend(WorkerMessage);

              case LccMessage.DataArrayIndexer[0] of
                DATAGRAM_PROTOCOL_CONFIGURATION :
                    begin
                      case LccMessage.DataArrayIndexer[1] and $F0 of
                        MCP_READ              : begin end;
                        MCP_READ_STREAM       : begin end;
                        MCP_READ_REPLY        :
                            begin
                              if LccMessage.DataArrayIndexer[1] and $08 = 0 then
                              begin
                                // Ok
                                case ExtractAddressSpace(LccMessage) of
                                  MSI_CDI             : begin
                                                          SendAckReply(LccMessage);
                                                          CDI.ProcessMessage(LccMessage);
                                                          Result := True;
                                                        end;
                                  MSI_ALL             : begin end;
                                  MSI_CONFIG          : begin
                                                          SendAckReply(LccMessage);
                                                          ConfigurationMem.ProcessMessage(LccMessage);
                                                          Result := True;
                                                        end;
                                  MSI_ACDI_MFG        : begin end;
                                  MSI_ACDI_USER       : begin end;
                                  {$IFDEF TRACTION}
                                  MSI_FDI             : begin
                                                          SendAckReply(LccMessage);
                                                          FDI.ProcessMessage(LccMessage);
                                                          Result := True;
                                                        end;
                                  MSI_FUNCTION_CONFIG : begin
                                                          SendAckReply(LccMessage);
                                                          FunctionConfiguration.ProcessMessage(LccMessage);
                                                          Result := True;
                                                        end;
                                  {$ENDIF}
                                end;
                              end else
                              begin
                                // Failure
                              end;
                            end;
                        MCP_READ_STREAM_REPLY : begin end;
                        MCP_WRITE             : begin end;
                        MCP_WRITE_STREAM      : begin end;
                        MCP_WRITE_REPLY       :
                            begin
                              if LccMessage.DataArrayIndexer[1] and $08 = 0 then
                              begin
                                // Ok
                                case ExtractAddressSpace(LccMessage) of
                                  MSI_CDI              : begin end; // Not writable
                                  MSI_ALL              : begin end; // Not writeable
                                  MSI_CONFIG           : begin
                                                           SendAckReply(LccMessage);
                                                           ConfigurationMem.ProcessMessage(LccMessage);
                                                           Result := True;
                                                         end;
                                  MSI_ACDI_MFG         : begin end;
                                  MSI_ACDI_USER        : begin end;
                                  {$IFDEF TRACTION}
                                  MSI_FDI              : begin end; // Not writeable
                                  MSI_FUNCTION_CONFIG  : begin
                                                           SendAckReply(LccMessage);
                                                           FunctionConfiguration.ProcessMessage(LccMessage);
                                                           Result := True;
                                                         end;
                                  {$ENDIF}
                                end;
                              end else
                              begin
                                // Failure
                              end;
                            end;
                        MCP_OPERATION :
                          begin
                            case LccMessage.DataArrayIndexer[1] of
                               MCP_OP_GET_CONFIG :
                                   begin
                                   end;
                               MCP_OP_GET_CONFIG_REPLY :
                                   begin
                                     SendAckReply(LccMessage);
                                     ConfigMemOptions.ProcessMessage(LccMessage);
                                     Result := True;
                                   end;
                               MCP_OP_GET_ADD_SPACE_INFO :
                                   begin
                                   end;
                               MCP_OP_GET_ADD_SPACE_INFO_PRESENT_REPLY,
                               MCP_OP_GET_ADD_SPACE_INFO_NOT_PRESENT_REPLY:
                                   begin
                                     SendAckReply(LccMessage);
                                     ConfigMemAddressSpaceInfo.ProcessMessage(LccMessage);
                                     Result := True;
                                   end;
                               MCP_OP_LOCK :
                                   begin
                                   end;
                               MCP_OP_GET_UNIQUEID :
                                   begin
                                   end;
                               MCP_OP_FREEZE :
                                   begin
                                   end;
                               MCP_OP_INDICATE :
                                   begin
                                   end;
                               MCP_OP_RESETS :
                                   begin
                                   end;

                            end;
                          end;
                    end;
              end;
            end;
        end;
    end;
  end;
end;

procedure TLccNode.SendAckReply(LccMessage: TLccMessage);
begin
  // Only Ack if we accept the datagram
  WorkerMessage.LoadDatagramAck(LccMessage.DestID, LccMessage.CAN.DestAlias, LccMessage.SourceID, LccMessage.CAN.SourceAlias, True);
  OwnerManager.DoRequestMessageSend(WorkerMessage);
end;


{ TConfigMemAddressSpaceInfo }

procedure TConfigMemAddressSpaceInfo.Add(_Space: Byte; _IsPresent, _IsReadOnly, _ImpliedZeroLowAddress: Boolean; _LowAddress, _HighAddress: DWord);
var
  Info: TConfigMemAddressSpaceInfoObject;
begin
  Info := TConfigMemAddressSpaceInfoObject.Create;
  Info.FAddressSpace := _Space;
  Info.FIsPresent := _IsPresent;
  Info.FIsReadOnly := _IsReadOnly;
  Info.FImpliedZeroLowAddress := _ImpliedZeroLowAddress;
  Info.FLowAddress := _LowAddress;
  Info.FHighAddress := _HighAddress;
  List.Add(Info);
end;

procedure TConfigMemAddressSpaceInfo.Clear;
var
  i: Integer;
begin
  try
    for i := 0 to List.Count - 1 do
      TObject(List[i]).Free;
  finally
    List.Clear
  end;
end;

constructor TConfigMemAddressSpaceInfo.Create(AnOwner: TComponent);
begin
  inherited;
  List := TList.Create;
end;

destructor TConfigMemAddressSpaceInfo.Destroy;
begin
  Clear;
  FreeAndNil(FList);
  inherited;
end;

function TConfigMemAddressSpaceInfo.FindByAddressSpace(Space: Byte): TConfigMemAddressSpaceInfoObject;
var
  i: Integer;
begin
  i := 0;
  Result := nil;
  while (i < Count) and not Assigned(Result) do
  begin
    if AddressSpace[i].AddressSpace = Space then
      Result := AddressSpace[i];
    Inc(i);
  end;
end;

function TConfigMemAddressSpaceInfo.GetAddressSpace(Index: Integer): TConfigMemAddressSpaceInfoObject;
begin
  Result := TConfigMemAddressSpaceInfoObject( List[Index])
end;

function TConfigMemAddressSpaceInfo.GetCount: Integer;
begin
  Result := List.Count
end;

procedure TConfigMemAddressSpaceInfo.LoadReply(LccMessage, OutMessage: TLccMessage);
var
  Info: TConfigMemAddressSpaceInfoObject;
begin
   // Decode the LccMessage
  Info := FindByAddressSpace( LccMessage.DataArrayIndexer[2]);
  if Assigned(Info) then
  begin
    if Info.IsPresent then
      OutMessage.DataArrayIndexer[1] := MCP_OP_GET_ADD_SPACE_INFO_PRESENT_REPLY
    else
      OutMessage.DataArrayIndexer[1] := MCP_OP_GET_ADD_SPACE_INFO_NOT_PRESENT_REPLY;
    OutMessage.DataArrayIndexer[2] := LccMessage.DataArrayIndexer[2];
    OutMessage.DataArrayIndexer[3] := _Highest(Info.FHighAddress);
    OutMessage.DataArrayIndexer[4] := _Higher(Info.FHighAddress);
    OutMessage.DataArrayIndexer[5] := _Hi(Info.FHighAddress);
    OutMessage.DataArrayIndexer[6] := _Lo(Info.FHighAddress);
    OutMessage.DataArrayIndexer[7] := 0;
    if Info.IsReadOnly then
      OutMessage.DataArrayIndexer[7] := OutMessage.DataArrayIndexer[7] or $01;
    OutMessage.DataCount := 8;
    if not Info.ImpliedZeroLowAddress then
    begin
      OutMessage.DataArrayIndexer[8] := _Highest(Info.FLowAddress);
      OutMessage.DataArrayIndexer[9] := _Higher(Info.FLowAddress);
      OutMessage.DataArrayIndexer[10] := _Hi(Info.FLowAddress);
      OutMessage.DataArrayIndexer[11] := _Lo(Info.FLowAddress);
      OutMessage.DataCount := 12;
    end;
  end else
  begin
    OutMessage.DataArrayIndexer[1] := MCP_OP_GET_ADD_SPACE_INFO_NOT_PRESENT_REPLY;
    OutMessage.DataArrayIndexer[2] := LccMessage.DataArrayIndexer[2];
    OutMessage.DataArrayIndexer[3] := 0;
    OutMessage.DataArrayIndexer[4] := 0;
    OutMessage.DataArrayIndexer[5] := 0;
    OutMessage.DataArrayIndexer[6] := 0;
    OutMessage.DataArrayIndexer[7] := $01;
    OutMessage.DataCount := 8;
  end;
  OutMessage.UserValid := True;
end;

function TConfigMemAddressSpaceInfo.ProcessMessage(LccMessage: TLccMessage): Boolean;
var
  Info: TConfigMemAddressSpaceInfoObject;
  IsPresent, ImpliedZeroAddress, IsReadOnly: Boolean;
  Space: Byte;
begin
  Result := True;
  IsPresent := LccMessage.DataArrayIndexer[1] = MCP_OP_GET_ADD_SPACE_INFO_PRESENT_REPLY;
  ImpliedZeroAddress := LccMessage.DataArrayIndexer[7] and $02 = 0;
  IsReadOnly := LccMessage.DataArrayIndexer[7] and $01 <> 0;
  Space := LccMessage.DataArrayIndexer[2];

  Info := FindByAddressSpace(Space);
  if not Assigned(Info) then
  begin
    if ImpliedZeroAddress then
      Add(Space,                                       // Space
          IsPresent,                                   // Present?
          IsReadOnly,                                  // Readonly?
          ImpliedZeroAddress,                          // Implied Zero Address
          0,                                           // Low Memory Address
          LccMessage.ExtractDataBytesAsInt(3, 6))      // High Memory Address
    else
      Add(Space,                                       // Space
          IsPresent,                                   // Present?
          IsReadOnly,                                  // Readonly?
          ImpliedZeroAddress,                          // Implied Zero Address
          LccMessage.ExtractDataBytesAsInt(8, 11),     // Low Memory Address
          LccMessage.ExtractDataBytesAsInt(3, 6));     // High Memory Address
    OwnerManager.DoConfigMemAddressSpaceInfoReply(OwnerManager.FindSourceNode(LccMessage, True), OwnerManager.FindDestNode(LccMessage, True), Space);
  end;
  Valid := True;                                       // Had at least one....
end;

{ TConfiguration }

constructor TConfiguration.Create(AnOwner: TComponent; AnAddressSpace: Byte);
begin
  inherited Create(AnOwner, AnAddressSpace);
  AutoSaveOnWrite := True;
end;

procedure TConfiguration.LoadFromFile;
begin
  if FileExists(FilePath) then
    AStream.LoadFromFile(FilePath);
end;

function TConfiguration.ReadAsString(Address: DWord): string;
var
  i: Integer;
  C: Char;
  Done: Boolean;
begin
  Result := '';
  if AStream.Size > Address then
  begin
    AStream.Position := Address;
    i := 0;
    Done := False;
    while (i + Address < AStream.Size) and not Done do
    begin
      C := Chr(AStream.ReadByte);
      if C <> #0 then
        Result := Result + C
      else
        Done := True;
      Inc(i)
    end;
  end;
end;

procedure TConfiguration.WriteRequest(LccMessage: TLccMessage);
var
  i: Integer;
  iStart, WriteCount: Integer;
  Address: DWord;
  AByte: Byte;
begin
  // Assumption is this is a datagram message
  if LccMessage.DataArrayIndexer[1] and $03 = 0 then
    iStart := 7
  else
    iStart := 6;
  WriteCount := LccMessage.DataCount - iStart;
  Address := LccMessage.ExtractDataBytesAsInt(2, 5);
  if Address + WriteCount > AStream.Size then
    AStream.Size := Address + WriteCount;
  AStream.Position := Address;
  for i := iStart to LccMessage.DataCount - 1 do
     AStream.WriteByte(LccMessage.DataArrayIndexer[i]);
  if AutoSaveOnWrite then
    AStream.SaveToFile(FilePath);
end;

{ TLccNetworkTree }

constructor TLccNetworkTree.Create(AnOwner: TComponent);
begin
  inherited Create(AnOwner);
  WorkerMessage := TLccMessage.Create;
end;

destructor TLccNetworkTree.Destroy;
begin
  FreeAndNil(FWorkerMessage);
  inherited Destroy;
end;

procedure TLccNetworkTree.DirectScanLocalNodes;
var
  i, j: Integer;
  Node: TLccOwnedNode;
  TreeNode: TTreeNode;
begin
  if Connected then
  begin
    if ShowRootNode then
    begin
      // Directly access local nodes
      Node := NodeManager.RootNode;
      if Node.Initialized then
        DoVerifiedNodeID(Node);
      for i := 0 to NodeManager.OwnedNodeList.Count - 1 do
      begin
        Node := TLccOwnedNode( NodeManager.OwnedNodeList[i]);
        if Node.Initialized then
          DoVerifiedNodeID(Node);
      end;
    end;

     if NetworkTreeProperties * [tp_AliasID] <> [] then
    begin
      if ShowRootNode then
      begin
        if NodeManager.RootNode.Initialized then
          ShowAliasIDChild(NodeManager.RootNode);
      end;
      if ShowLocallNodes then
      begin
        for i := 0 to NodeManager.OwnedNodeList.Count - 1 do
        begin
          Node := TLccOwnedNode( NodeManager.OwnedNodeList[i]);
          if Node.Initialized then
            ShowAliasIDChild(Node)
        end;
      end
    end;

    if NetworkTreeProperties * [tp_Protocols] <> [] then
    begin
      if ShowRootNode then
      begin
        if NodeManager.RootNode.Initialized then
          DoProtocolIdentifyReply(NodeManager.RootNode, nil);
      end;

      if ShowLocallNodes then
      begin
        for i := 0 to NodeManager.OwnedNodeList.Count - 1 do
        begin
          Node := TLccOwnedNode( NodeManager.OwnedNodeList[i]);
          if Node.Initialized then
            DoProtocolIdentifyReply(Node, nil);
        end;
      end
    end;
    if NetworkTreeProperties * [tp_Snip] <> [] then
    begin
      if ShowRootNode then
      begin
        if NodeManager.RootNode.Initialized then
          DoSimpleNodeIdentReply(NodeManager.RootNode, nil);
      end;

      if ShowLocallNodes then
      begin
        for i := 0 to NodeManager.OwnedNodeList.Count - 1 do
        begin
          Node := TLccOwnedNode( NodeManager.OwnedNodeList[i]);
          if Node.Initialized then
            DoSimpleNodeIdentReply(Node, nil);
        end;
      end;
    end;
    if NetworkTreeProperties * [tp_ConsumedEvents] <> [] then
    begin
      if ShowRootNode then
      begin
        if NodeManager.RootNode.Initialized then
        begin
          Node := NodeManager.RootNode;
          for j := 0 to Node.EventsConsumed.Count - 1 do
            DoConsumerIdentified(Node, Node.EventsConsumed[j].FID, Node.EventsConsumed[j].State);
        end;
      end;

      if ShowLocallNodes then
      begin
        for i := 0 to NodeManager.OwnedNodeList.Count - 1 do
        begin
          Node := TLccOwnedNode( NodeManager.OwnedNodeList[i]);
          for j := 0 to Node.EventsConsumed.Count - 1 do
            DoConsumerIdentified(Node, Node.EventsConsumed[j].FID, Node.EventsConsumed[j].State);
        end;
      end;
    end;
    if NetworkTreeProperties * [tp_ProducedEvents] <> [] then
    begin
      if ShowRootNode then
      begin
        if NodeManager.RootNode.Initialized then
        begin
          Node := NodeManager.RootNode;
          for j := 0 to Node.EventsConsumed.Count - 1 do
            DoProducerIdentified(Node, Node.EventsProduced[j].FID, Node.EventsProduced[j].State);
        end;
      end;

      if ShowLocallNodes then
      begin
        for i := 0 to NodeManager.OwnedNodeList.Count - 1 do
        begin
          Node := TLccOwnedNode( NodeManager.OwnedNodeList[i]);
          for j := 0 to Node.EventsProduced.Count - 1 do
            DoProducerIdentified(Node, Node.EventsProduced[j].FID, Node.EventsProduced[j].State);
        end;
      end;
    end;
  end
end;

procedure TLccNetworkTree.InquireBasedOnNetworkTreeProperites(LccNode: TLccNode);
begin
  if Connected then
  begin
    if NetworkTreeProperties * [tp_Protocols] <> [] then
    begin
      WorkerMessage.LoadProtocolIdentifyInquiry(NodeManager.RootNodeID, NodeManager.RootNodeAlias, LccNode.NodeID, LccNode.AliasID);
      NodeManager.SendLccMessage(WorkerMessage);
    end;
    if NetworkTreeProperties * [tp_Snip] <> [] then
    begin
      WorkerMessage.LoadSimpleNodeIdentInfoRequest(NodeManager.RootNodeID, NodeManager.RootNodeAlias, LccNode.NodeID, LccNode.AliasID);
      NodeManager.SendLccMessage(WorkerMessage);
    end;
    if NetworkTreeProperties * [tp_ProducedEvents] <> [] then
    begin
      WorkerMessage.LoadIdentifyEventsAddressed(NodeManager.RootNodeID, NodeManager.RootNodeAlias, LccNode.NodeID, LccNode.AliasID);
      NodeManager.SendLccMessage(WorkerMessage);
    end;
    if NetworkTreeProperties * [tp_ConsumedEvents] <> [] then
    begin
      WorkerMessage.LoadIdentifyEventsAddressed(NodeManager.RootNodeID, NodeManager.RootNodeAlias, LccNode.NodeID, LccNode.AliasID);
      NodeManager.SendLccMessage(WorkerMessage);
    end;
  end;
end;

procedure TLccNetworkTree.DoAliasIDChanged(LccNode: TLccNode);
var
  Node: TTreeNode;
begin
  BeginUpdate;
  try
    if Connected then
    begin
      Node := FindOrCreateNewTreeNodeByLccNodeObject(LccNode);
      if Assigned(Node) then
      begin

      end
    end else
      Items.Clear;
  finally
    EndUpdate;
  end;
end;

procedure TLccNetworkTree.DoConsumerIdentified(SourceLccNode: TLccNode; var Event: TEventID; State: TEventState);
var
  Node, EventNode, Child: TTreeNode;
begin
  BeginUpdate;
  try
    if Connected then
    begin
      Node := FindOrCreateNewTreeNodeByLccNodeObject(SourceLccNode);
      if Assigned(Node) then
      begin
        if NetworkTreeProperties * [tp_ConsumedEvents] = [] then
        begin  // Remove the node if not suppose to show Consumed Events
          EventNode := FindOrCreateNewTreeNodeByName(Node, 'Consumed Events', True);
          if Assigned(EventNode) then
            Delete(EventNode);
        end else
        begin
          EventNode := FindOrCreateNewTreeNodeByName(Node, 'Consumed Events', False);
          if Assigned(EventNode) then
            Child := FindOrCreateNewTreeNodeByName(EventNode, EventIDToString(Event), False);
        end;
      end
    end else
      Items.Clear;
  finally
    EndUpdate;
  end;
end;

procedure TLccNetworkTree.DoCreateLccNode(SourceLccNode: TLccNode);
var
  Node: TTreeNode;
begin
  BeginUpdate;
  try
    if Connected then
    begin
      Node := FindOrCreateNewTreeNodeByLccNodeObject(SourceLccNode);
      if Assigned(Node) then
      begin

      end;
    end else
      Items.Clear;
  finally
    EndUpdate;
  end;
end;

procedure TLccNetworkTree.DoDestroyLccNode(LccNode: TLccNode);
var
  Node: TTreeNode;
begin
  BeginUpdate;
  try
    if Connected then
    begin
      Node := Items.FindNodeWithData(LccNode);
      if Node <> nil then
        Items.Delete(Node);
    end else
      Items.Clear;
  finally
    EndUpdate;
  end;
end;

procedure TLccNetworkTree.DoNodeIDChanged(LccNode: TLccNode);
var
  Node: TTreeNode;
begin
  BeginUpdate;
  try
    if Connected then
    begin
      Node := FindOrCreateNewTreeNodeByLccNodeObject(LccNode);
      if Assigned(Node) then
        Node.Text := LccNode.NodeIDStr;
    end else
      Items.Clear;
  finally
    EndUpdate
  end;
end;

procedure TLccNetworkTree.DoProducerIdentified(SourceLccNode: TLccNode; var Event: TEventID; State: TEventState);
var
  Node, EventNode, Child: TTreeNode;
begin
  BeginUpdate;
  try
    if Connected then
    begin
      Node := FindOrCreateNewTreeNodeByLccNodeObject(SourceLccNode);
      if Assigned(Node) then
      begin
        if NetworkTreeProperties * [tp_ProducedEvents] = [] then
        begin  // Remove the node if not suppose to show Consumed Events
          EventNode := FindOrCreateNewTreeNodeByName(Node, 'Produced Events', True);
          if Assigned(EventNode) then
            Delete(EventNode);
        end else
        begin
          EventNode := FindOrCreateNewTreeNodeByName(Node, 'Produced Events', False);
          if Assigned(EventNode) then
            Child := FindOrCreateNewTreeNodeByName(EventNode, EventIDToString(Event), False);
        end;
      end
    end else
      Items.Clear;
  finally
    EndUpdate
  end;
end;

procedure TLccNetworkTree.DoProtocolIdentifyReply(SourceLccNode, DestLccNode: TLccNode);
var
  Node, PIP, Child: TTreeNode;
begin
  BeginUpdate;
  try
    if Connected then
    begin
      Node := FindOrCreateNewTreeNodeByLccNodeObject(SourceLccNode);
      if Assigned(Node) then
      begin
        PIP := FindOrCreateNewTreeNodeByName(Node, 'Protocol Identification Protocol (PIP)', False);
        if Assigned(PIP) then
        begin
          PIP.DeleteChildren;
          if SourceLccNode.ProtocolSupport.ACDI then
            Items.AddChild(PIP, 'ACDI');
          if SourceLccNode.ProtocolSupport.CDI then
            Items.AddChild(PIP, 'CDI');
          if SourceLccNode.ProtocolSupport.Datagram then
            Items.AddChild(PIP, 'Datagram');
          if SourceLccNode.ProtocolSupport.FDisplay then
            Items.AddChild(PIP, 'Display');
          if SourceLccNode.ProtocolSupport.EventExchange then
            Items.AddChild(PIP, 'Events');
          {$IFDEF TRACTION}
          if SourceLccNode.ProtocolSupport.FDI then
            Items.AddChild(PIP, 'FDI');
          {$ENDIF}
          if SourceLccNode.ProtocolSupport.Identification then
            Items.AddChild(PIP, 'Identification');
          if SourceLccNode.ProtocolSupport.MemConfig then
            Items.AddChild(PIP, 'MemConfig');
          if SourceLccNode.ProtocolSupport.RemoteButton then
            Items.AddChild(PIP, 'RemoteButton');
          if SourceLccNode.ProtocolSupport.Reservation then
            Items.AddChild(PIP, 'Reservation');

          if SourceLccNode.ProtocolSupport.SimpleNodeInfo then
            Items.AddChild(PIP, 'SNIP (SNII)');
          if SourceLccNode.ProtocolSupport.Stream then
            Items.AddChild(PIP, 'Stream');
          if SourceLccNode.ProtocolSupport.Teach_Learn then
            Items.AddChild(PIP, 'Teach Learn');
          {$IFDEF TRACTION}
          if SourceLccNode.ProtocolSupport.TractionControl then
            Items.AddChild(PIP, 'TractionControl');
          if SourceLccNode.ProtocolSupport.TractionProxy then
            Items.AddChild(PIP, 'TractionProxy');
          if SourceLccNode.ProtocolSupport.SimpleTrainNodeInfo then
            Items.AddChild(PIP, 'Simple Train PIP Information Protocol (STNIP');
          if SourceLccNode.ProtocolSupport.FunctionConfiguration then
            Items.AddChild(PIP, 'Function Configuration');
          {$ENDIF}
        end;
      end else
        Items.Clear;
    end;
  finally
    EndUpdate
  end;
end;

procedure TLccNetworkTree.DoSimpleNodeIdentReply(SourceLccNode, DestLccNode: TLccNode);
var
  Node, SNIP, Child: TTreeNode;
begin
  BeginUpdate;
  try
    if Connected then
    begin
      Node := FindOrCreateNewTreeNodeByLccNodeObject(SourceLccNode);
      if Assigned(Node) then
      begin
        SNIP := FindOrCreateNewTreeNodeByName(Node, 'Simple Node Information Protocol (SNIP)', False);
        if Assigned(SNIP) then
        begin
          SNIP.DeleteChildren;
          Items.AddChild(SNIP, 'Version = ' + IntToStr(SourceLccNode.SimpleNodeInfo.Version));
          Items.AddChild(SNIP, 'Manufacturer: ' + SourceLccNode.SimpleNodeInfo.Manufacturer);
          Items.AddChild(SNIP, 'Model: ' + SourceLccNode.SimpleNodeInfo.Model);
          Items.AddChild(SNIP, 'Software Version: '+ SourceLccNode.SimpleNodeInfo.SoftwareVersion);
          Items.AddChild(SNIP, 'Hardware Version: ' + SourceLccNode.SimpleNodeInfo.HardwareVersion);
          Items.AddChild(SNIP, 'User Version = ' + IntToStr(SourceLccNode.SimpleNodeInfo.UserVersion));
          Items.AddChild(SNIP, 'User Name: ' + SourceLccNode.SimpleNodeInfo.UserName);
          Items.AddChild(SNIP, 'User Description: ' + SourceLccNode.SimpleNodeInfo.UserDescription);
        end;
      end else
        Items.Clear;
    end;
  finally
    Endupdate;
  end;
end;

procedure TLccNetworkTree.DoVerifiedNodeID(SourceLccNode: TLccNode);
var
  Node: TTreeNode;
begin
  BeginUpdate;
  try
    if Connected then
    begin
      Node := FindOrCreateNewTreeNodeByLccNodeObject(SourceLccNode);
      if Assigned(Node) then
      begin
        Node.Text := SourceLccNode.NodeIDStr;
        if not (SourceLccNode is TLccOwnedNode) then
        begin
          InquireBasedOnNetworkTreeProperites(SourceLccNode);
          ShowAliasIDChild(SourceLccNode);
        end;
      end;
    end else
      Items.Clear;
  finally
    EndUpdate
  end
end;

procedure TLccNetworkTree.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  case Operation of
    opInsert :
      begin
        if AComponent is TLccNodeManager then
        begin
          if NodeManager = nil then
            NodeManager := AComponent as TLccNodeManager;
        end;
      end;
    opRemove :
      begin
        if AComponent = NodeManager then
          NodeManager := nil;
      end;
  end;
end;

procedure TLccNetworkTree.ShowAliasIDChild(LccNode: TLccNode);
var
  Node, AliasIDNode, Child: TTreeNode;
begin
  BeginUpdate;
  try
    Node := FindOrCreateNewTreeNodeByLccNodeObject(LccNode);
    if Assigned(Node) then
    begin
      if NetworkTreeProperties * [tp_AliasID] = [] then
      begin
        AliasIDNode := FindOrCreateNewTreeNodeByName(Node, 'AliasID', True);
        if Assigned(AliasIDNode) then
          Items.Delete(AliasIDNode);
      end else
      begin
        AliasIDNode := FindOrCreateNewTreeNodeByName(Node, 'AliasID', False);
        if Assigned(AliasIDNode) then
          Child := FindOrCreateNewTreeNodeByName(AliasIDNode, '0x' + IntToHex(LccNode.AliasID, 4), False);
      end;
    end;
  finally
    EndUpdate;
  end;
end;

procedure TLccNetworkTree.ScanNetwork;
begin
  if Connected then
  begin
    if Assigned(NodeManager) then
    begin
      WorkerMessage.LoadVerifyNodeID(NodeManager.RootNodeID, NodeManager.RootNodeAlias);
      NodeManager.SendLccMessage(WorkerMessage);

      DirectScanLocalNodes;
    end else
      Items.Clear;
  end;
end;

procedure TLccNetworkTree.SetConnected(AValue: Boolean);
begin
  if FConnected = AValue then Exit;
  FConnected := AValue;
  if csDesigning in ComponentState then Exit;
  if FConnected then
    ScanNetwork
  else begin
    BeginUpdate;
    try
      Items.Clear;
    finally
      EndUpdate;
    end;
  end;
end;

procedure TLccNetworkTree.SetNetworkTreeProperties(AValue: TLccNetworkTreePropetiesSet);
begin
  if FNetworkTreeProperties = AValue then Exit;
  FNetworkTreeProperties := AValue;
  Items.Clear;
  ScanNetwork;
end;

procedure TLccNetworkTree.SetShowLocalNodes(AValue: Boolean);
begin
  if FShowLocalNodes=AValue then Exit;
  FShowLocalNodes:=AValue;
  BeginUpdate;
  try
    Items.Clear;
  finally
    EndUpdate;
  end;
  ScanNetwork;
end;

procedure TLccNetworkTree.SetShowRootNode(AValue: Boolean);
begin
  if FShowRootNode=AValue then Exit;
  FShowRootNode:=AValue;
  BeginUpdate;
  try
    Items.Clear;
  finally
    EndUpdate;
  end;
  ScanNetwork;
end;

function TLccNetworkTree.FindOrCreateNewTreeNodeByLccNodeObject(LccNode: TLccNode): TTreeNode;
begin
  Result := Items.FindNodeWithData(LccNode);
  if not Assigned(Result) and not NullNodeID(LccNode.NodeID) then
    Result := Items.AddChildObject(nil, LccNode.NodeIDStr, LccNode);          // Add a new item
end;

function TLccNetworkTree.FindOrCreateNewTreeNodeByName(AParent: TTreeNode; AName: string; FindOnly: Boolean): TTreeNode;
begin
  if AParent = nil then
  begin
    Result := Items.FindNodeWithText(AName);
    if FindOnly then Exit;
    if not Assigned(Result) then
      Result := Items.AddChildObject(nil, AName, nil);          // Add a new item
  end else
  begin
    Result := AParent.FindNode(AName);
    if FindOnly then Exit;
    if not Assigned(Result) then
      Result := Items.AddChildObject(AParent, AName, nil);          // Add a new item
  end;
end;

initialization
  TotalSNIPMessages := 0;
  TotalSTNIPMessage := 0;
  RegisterClass(TLccNodeManager);
  RegisterClass(TLccNetworkTree);

finalization

end.



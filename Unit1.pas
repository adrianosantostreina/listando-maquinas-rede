unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TForm1 = class(TForm)
    Button1: TButton;
    ListBox1: TListBox;
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

type
  PNetResourceArray = ^TNetResourceArray;
  TNetResourceArray = array[0..100] of TNetResource;

function CreateNetResourceList(ResourceType: DWord;
                              NetResource: PNetResource;
                              out Entries: DWord;
                              out List: PNetResourceArray): Boolean;
var
  EnumHandle: THandle;
  BufSize: DWord;
  Res: DWord;
begin
  Result := False;
  List := Nil;
  Entries := 0;
  if WNetOpenEnum(RESOURCE_GLOBALNET,
                  ResourceType,
                  0,
                  NetResource,
                  EnumHandle) = NO_ERROR then begin
    try
      BufSize := $4000;  // 16 kByte
      GetMem(List, BufSize);
      try
        repeat
          Entries := DWord(-1);
          FillChar(List^, BufSize, 0);
          Res := WNetEnumResource(EnumHandle, Entries, List, BufSize);
          if Res = ERROR_MORE_DATA then
          begin
            ReAllocMem(List, BufSize);
          end;
        until Res <> ERROR_MORE_DATA;

        Result := Res = NO_ERROR;
        if not Result then
        begin
          FreeMem(List);
          List := Nil;
          Entries := 0;
        end;
      except
        FreeMem(List);
        raise;
      end;
    finally
      WNetCloseEnum(EnumHandle);
    end;
  end;
end;

procedure ScanNetworkResources(ResourceType, DisplayType: DWord; List: TStrings);

procedure ScanLevel(NetResource: PNetResource);
var
  Entries: DWord;
  NetResourceList: PNetResourceArray;
  i: Integer;
begin
  if CreateNetResourceList(ResourceType, NetResource, Entries, NetResourceList) then try
    for i := 0 to Integer(Entries) - 1 do
    begin
      if (DisplayType = RESOURCEDISPLAYTYPE_GENERIC) or
        (NetResourceList[i].dwDisplayType = DisplayType) then begin
        List.AddObject(NetResourceList[i].lpRemoteName,
                      Pointer(NetResourceList[i].dwDisplayType));
      end;
      if (NetResourceList[i].dwUsage and RESOURCEUSAGE_CONTAINER) <> 0 then
        ScanLevel(@NetResourceList[i]);
    end;
  finally
    FreeMem(NetResourceList);
  end;
end;

begin
  ScanLevel(Nil);
end;


procedure TForm1.Button1Click(Sender: TObject);
begin
  ScanNetworkResources(RESOURCETYPE_DISK, RESOURCEDISPLAYTYPE_SERVER, ListBox1.Items);
end;

end.

unit uPacketVisual;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, math, 
  Dialogs, ExtCtrls, ImgList, ComCtrls, ToolWin, uPacketView, pfHeader, uGlobal,
  StdCtrls;

const
    PCK_NORMAL = 0;
    PCK_DROPPED = 1;
    PCK_CHANGED = 2;
    PCK_NEW = 3;

type
  tpck_struct = packed record
      p : TPacket;
      from_server : Boolean;
      flags : Byte;
      caller : TObject;
      pck_num : Integer;
  end;
  ppck_struct = ^tpck_struct;
  
  TfVisual = class(TFrame)
    pnlView: TPanel;
    pnlList: TPanel;
    Splitter1: TSplitter;
    ImageList2: TImageList;
    imgBT: TImageList;
    Panel4: TPanel;
    ToolBar1: TToolBar;
    tbtnClear: TToolButton;
    ToolButton2: TToolButton;
    ToolButton4: TToolButton;
    ToolButton3: TToolButton;
    ToolButton5: TToolButton;
    ListView5: TListView;
    fixTimer: TTimer;
    tbtnMap: TToolButton;
    ToolButton1: TToolButton;
    lblTime: TLabel;
    ToolButton6: TToolButton;
    procedure ListView5Click(Sender: TObject);
    procedure ListView5KeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure ListView5Resize(Sender: TObject);
    procedure fixTimerTimer(Sender: TObject);
    procedure tbtnClearClick(Sender: TObject);
    procedure tbtnMapClick(Sender: TObject);
    procedure ToolButton1Click(Sender: TObject);
    procedure ListView5CustomDrawItem(Sender: TCustomListView; Item: TListItem;
      State: TCustomDrawState; var DefaultDraw: Boolean);
    procedure ToolButton6Click(Sender: TObject);
  private
    procedure msgPckVisual(var msg: TMessage); Message WM_VISUAL_PACKET;
  public
    Connect : TObject;
    PacketView: tfPView;
    Dump : TStringList;
    CreateTime : TDateTime;

    procedure ProcessPacket(newpacket: TPacket; FromServer: boolean; Caller: TObject; PacketNumber:integer; flags : Byte);

    procedure init;
    procedure finit;
  end;


procedure PckVisual(v : TfVisual; p : tpck_struct);


implementation

uses uMain, uL2GS_Connect, uFilterForm, uMap;

{$R *.dfm}

procedure PckVisual(v : TfVisual; p : tpck_struct);
begin
    SendMessage(v.Handle, WM_VISUAL_PACKET, 0, Integer( @p ) );
end;

{ TfVisual }


procedure TfVisual.finit;
begin
    PacketView.Free;
    Dump.Free;    
end;

procedure TfVisual.init;
begin
    PacketView := tfPView.Create(self);
    PacketView.Parent := pnlView;
    PacketView.Show;
    Dump := TStringList.Create;
    ListView5.DoubleBuffered := true;
end;

procedure TfVisual.ListView5Click(Sender: TObject);
begin
  if ListView5.SelCount=1 then
    begin
      PacketView.ParsePacket(ListView5.Selected.Caption, Dump.Strings[ListView5.Selected.Index]);
    end;
end;

procedure TfVisual.ListView5CustomDrawItem(Sender: TCustomListView;
  Item: TListItem; State: TCustomDrawState; var DefaultDraw: Boolean);
var
    f : Integer;
    c : TColor;
begin
    f := Integer(item.Data);
    if f = 0 then begin
        if Item.Index mod 2 = 0 then
        begin
            Sender.Canvas.Font.Color := clBlack;
            Sender.Canvas.Brush.Color := $Eeeeee;
        end else
        begin
            Sender.Canvas.Font.Color := clBlack;
            Sender.Canvas.Brush.Color := clWhite;
        end;
    end else begin
        Sender.Canvas.Font.Color := clBlack;
        case f of
            PCK_DROPPED : begin c := $534643; {Sender.Canvas.Font.Color := clWhite;} end;
            PCK_CHANGED : c := $62c17f;
            PCK_NEW : c := $8082d0;
            else c := clWhite;
        end;
        Sender.Canvas.Brush.Color := c;
    end;
end;

procedure TfVisual.ListView5KeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  ListView5Click(Sender);
end;

procedure TfVisual.ListView5Resize(Sender: TObject);
begin
    ListView5.Columns.Items[0].Width := ListView5.Width - ListView5.Columns.Items[1].Width - ListView5.Columns.Items[2].Width - 40;
end;

procedure TfVisual.msgPckVisual(var msg: TMessage);
var
    ps : ppck_struct;
begin
    ps := Pointer(msg.LParam);
    ProcessPacket( ps.p, ps.from_server, ps.caller, ps.pck_num, ps.flags );
end;

procedure TfVisual.ProcessPacket(newpacket: TPacket; FromServer: boolean;
  Caller: TObject; PacketNumber: integer; flags : byte);
  //=========================================
  // локальные процедуры
  //=========================================
  Procedure AddToListView5(ItemImageIndex : byte; ItemCaption : String; ItemPacketNumber : LongWord; ItemId : byte; ItemSubId, ItemSub2Id : word; Visible : boolean);
  var
    str : string;
  begin
    with ListView5.Items.Add do begin
      //им€ пакета
      Caption := ItemCaption;
      //код иконки
      ImageIndex := ItemImageIndex;
      Data := Pointer(flags);
      //номер
      SubItems.Add(IntToStr(ItemPacketNumber));
      //код пакета

//      if (GlobalProtocolVersion=AION)then // дл€ јйон 2.1 - 2.6
//        //client/server one ID packets: c(ID)
//        str := IntToHex(ItemId, 2)
//      else //дл€ Lineage II
      begin
//        if (GlobalProtocolVersion=AION27)then // дл€ јйон 2.7
//          //client/server mybe two ID packets: c(ID)
//          if (ItemSubId=0) then
//            str := IntToHex(ItemId, 2)
//          else
//            str := IntToHex(ItemSubId, 4)
//        else //дл€ Lineage II
        begin
//          if (GlobalProtocolVersion<GRACIA) then
//          begin
//            //фиксим пакет 39 дл€ хроник C4-C5-Interlude
//            //client two ID packets: (subID)
//            if (ItemId in [$39, $D0]) then
//              str := IntToHex(ItemSubId, 4)
//            else
//              str := IntToHex(ItemId, 2)
//          end
//          else
          begin
            //client three ID packets: c(ID)h(subID)
            if (Itemid=$D0) and (((Itemsub2id>=$5100) and (Itemsub2id<=$5105)) or (Itemsub2id=$5A00)) then
              str := IntToHex(ItemId, 2)+IntToHex(ItemSub2Id, 4)
            else
            begin
              //client two ID packets: h(subID)
              if (Itemid=$D0) then
                str := IntToHex(ItemSubId, 4)
              else
              begin
                //server four ID packets: c(ID)h(subID)h(sub2ID)
                if (ItemSubId=$FE97) or (ItemSubId=$FE98) or (ItemSubId=$FEB7) then
                  str := IntToHex(ItemSubId, 4)+IntToHex(ItemSub2Id, 4)
                else
                begin
                  if ItemSubId = 0 then
                    //client/server one ID packets: c(ID)
                    str := IntToHex(ItemId, 2)
                  else
                  begin
                    //client/server two ID packets: c(ID)h(subID)
                    str := IntToHex(ItemSubId, 4);
                  end;
                end;
              end;
            end;
          end;
        end;
      end;
      SubItems.Add(str);
      if not Visible then MakeVisible(false);
    end;
  end;

  Procedure AddToPacketFilterUnknown(ItemFromServer : boolean; ItemId : byte; ItemSubId, ItemSub2Id : Word; ItemChecked : boolean);
  var
    CurrentList : TListView;
    currentpackedfrom : TStringList;
    str:string;
  begin
    if ItemFromServer then begin
      currentpackedfrom := PacketsFromS;
      CurrentList := fPFilter.ListView1
    end else begin
      currentpackedfrom := PacketsFromC;
      CurrentList := fPFilter.ListView2;
    end;
    with CurrentList.Items.Add do begin
      if ItemSubId = 0 then
          str := IntToHex(ItemId, 2)
      else
      begin
        str := IntToHex(ItemSubId, 4);
      end;
      Caption :=str;
      Checked := ItemChecked;
      SubItems.Add('Unknown'+str);
      if length(str)=2 then
        currentpackedfrom.Append(str+'=Unknown:')
      else
        currentpackedfrom.Append(str+'=Unknown:h(SubId)');
    end;
  end;
//=========================================var
var
  id: Byte;
  subid, sub2id: word;
  pname : string;
  isknown : boolean;
  IsShow : boolean;
  pkt : TPacket;
  ps : AnsiString;
begin
  if not GlobalOptions.PacketsLog then exit; //не ведем лог пакетов
  ps := Copy(newpacket.data, 1, Length(newpacket.data));
  pkt.Reset(ps);

  if PacketNumber < 0 then exit; //или -1 0_о
//  if PacketNumber >= Dump.Count then exit; //или индекс оф боундс -)
  if pkt.Size = 0 then exit; // если пустой пакет выходим
  if (FromServer and not ToolButton4.Down)
    or (not FromServer and not ToolButton3.Down) then exit;



//  if (GlobalProtocolVersion<=AION27)then // дл€ јйон 2.7 двухбайтное ID
//  begin
//    //client/server maybe two ID packets: c(ID)
//    id := pkt.Data[0];
//    SubId := Word(Byte(pkt.Data[1]) shl 8 + id);
//    Sub2ID:=0;   //пакет закончилс€, пишем в sub2id 0
//  end
//  else
  begin
    if pkt.Size=1 then
    begin
      id := Ord(pkt.Data[1]);
      SubID:=0;    //пакет закончилс€, пишем в subid 0
      Sub2ID:=0;   //пакет закончилс€, пишем в sub2id 0
    end
    else
    begin
      if not FromServer then //от клиента
      begin //дл€ двух и трехбайтных ID
        //client three ID packets: c(ID)h(subID)
        //готовим sub2id дл€ трехбайтного пакета - содержит 2 и 3 байт
        //надо разворачивать младшие байты числа в младшие позиции
        id := Ord(pkt.Data[2]);
        Sub2Id := Word(id shl 8+Byte(pkt.Data[3]));
        //готовим subid дл€ двухбайтного пакета - содержит 1 и 2 байт
        //это насто€щий ID
        id := Ord(pkt.Data[1]);
        SubId := Word(id shl 8+Byte(pkt.Data[2]));
      end
      else //от сервера
      begin  //дл€ двух и четырехбайтных ID
        //готовим дл€ sub2id
        id := ord(pkt.Data[3]);
        Sub2Id := Word(id shl 8+Byte(pkt.Data[4]));
        //это насто€щий ID
        id := Ord(pkt.Data[1]);
        SubId := Word(id shl 8+Byte(pkt.Data[2]));
      end;
    end;
  end;
  isknown := GetPacketName(id, subid, sub2id, FromServer, pname, IsShow);
  if not isknown then
    AddToPacketFilterUnknown(FromServer, id, subid, sub2id,  True);
    
  if IsShow then begin
        dump.Add( PrepareVisualPacket(pkt, FromServer) );
        AddToListView5(math.ifthen(FromServer, 0, 1), Pname, PacketNumber, Id, subid, sub2id, not ToolButton5.Down);
  end;


end;

procedure TfVisual.tbtnClearClick(Sender: TObject);
begin
    Dump.Clear;
    ListView5.Clear;
end;

procedure TfVisual.tbtnMapClick(Sender: TObject);
begin
    uMap.Init( TL2GS_Connect(Connect).getEngine );
end;

procedure TfVisual.fixTimerTimer(Sender: TObject);
var
    p : WINDOWPOS;
    d : TDateTime;
begin
    // исправл€ем кос€чное поведение TListView,
    // надо измен€ть ширину столбцов динамически при приходе новых данных,
    // а не только при ресайзе контрола

    p.hwnd := ListView5.Handle;
    p.hwndInsertAfter := HWND_NOTOPMOST;

    p.x := 0;
    p.y := 0;
    p.cx := 0;
    p.cy := 0;
    p.flags := SWP_SHOWWINDOW;

    SendMessage( p.hwnd, WM_WINDOWPOSCHANGED, 0, Integer( @p ) );

    // обновим врем€ коннекта
    d := now;
    lblTime.Caption := TimeToStr(d-CreateTime)+ ' / ' + TimeToStr(CreateTime);
end;

procedure TfVisual.ToolButton1Click(Sender: TObject);
begin
    TL2GS_Connect(Connect).getContext.OutboundClient.Disconnect;
end;

procedure TfVisual.ToolButton6Click(Sender: TObject);
begin
//    TL2GS_Connect(Connect).getContext.LocalClientActive := false;
end;

end.

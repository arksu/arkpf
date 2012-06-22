unit uPlugins;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, ComCtrls;

type
  TfPlugins = class(TForm)
    pnlPlugins: TPanel;
    pnlEdit: TPanel;
    edCharname: TEdit;
    Label1: TLabel;
    Splitter1: TSplitter;
    lvPlugins: TListView;
    btnRefresh: TButton;
    btnUp: TButton;
    btnDown: TButton;
    btnSet: TButton;
    btnSaveOrder: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnRefreshClick(Sender: TObject);
    procedure lvPluginsChange(Sender: TObject; Item: TListItem;
      Change: TItemChange);
    procedure lvPluginsClick(Sender: TObject);
    procedure btnSetClick(Sender: TObject);
    procedure btnUpClick(Sender: TObject);
    procedure btnDownClick(Sender: TObject);
    procedure btnSaveOrderClick(Sender: TObject);
  private
    { Private declarations }
  public
        procedure Init;
  end;

var
  fPlugins: TfPlugins;

implementation

uses
    uGlobal, uMain;

{$R *.dfm}

procedure TfPlugins.btnDownClick(Sender: TObject);
var
  Index: integer;
  temp : TListItem;
begin
    if lvPlugins.SelCount>0 then
    begin
      Index := lvPlugins.Selected.Index;
      if Index<lvPlugins.Items.Count then
      begin
        temp := lvPlugins.Items.Insert(Index+2);
        temp.Assign(lvPlugins.Items.Item[Index]);
        lvPlugins.Items.Delete(Index);
        // fix display so moved item is selected/focused
        lvPlugins.Selected := temp;
        lvPlugins.ItemFocused := temp;
        btnSaveOrderClick(nil);
        end;
    end;
end;

procedure TfPlugins.btnRefreshClick(Sender: TObject);
var
    list : TStringList;
    item : TListItem;
    s : string;
    p : TPlugin;
    plist : TList;
    i, ii : Integer;
    found, f : Boolean;

    procedure add_plug(fname : string);
    begin
        found := false;
        // если такой плагин уже есть просто добавим
        i := plist.Count-1;
        while i >= 0 do begin
            if TPlugin( plist[i] ).FileName = fname then begin
                found := true;
                Plugins.Add( plist[i] );
                if item.Checked then
                    TPlugin( plist[i] ).Load;
                plist.Delete(i);
                Break;
            end;
            Dec(i);
        end;

        // если нет - создадим
        if not found then begin
            p := TPlugin.Create( fname );
            item.Data := p;
            p.CharName := item.SubItems[0];

            if item.Checked then begin
                p.Load;
            end;
        end;
    end;

begin
    // копируем все существующие плагины
    plist := TList.Create;
    for i := 0 to Plugins.Count-1 do
        plist.Add(Plugins[i]);
    // очистим список
    Plugins.Clear;

    lvPlugins.Items.BeginUpdate;
    lvPlugins.Items.Clear;

    //Сначала грузим в порядке очереди с инишки и компилим по надобности.
    if assigned(Options) then
    begin
      ii := 0;
      while ii < Options.ReadInteger('plugins','count',0) do
      begin
        s := Options.ReadString('plugins','name'+inttostr(ii),'');

        if fileexists(AppPath+'plugins\'+s) then begin
            item := lvPlugins.Items.Add;
            item.Caption := s;
            item.SubItems.Add( Options.ReadString('plugins', 'char'+inttostr(ii), '' ));
            item.Checked := Options.ReadBool( 'plugins', 'chk'+inttostr(ii), false );

            add_plug(AppPath + 'plugins\'+s);
        end;
        Inc(ii);
      end;
    end;


    list := TStringList.Create;
    FindFiles( AppPath + 'plugins\*.dll', list );

    for s in list do begin
        f := false;
        for ii := 0 to lvPlugins.Items.Count - 1 do
        begin
            if lvPlugins.Items[ii].Caption = s then begin
                f := True;
                Break;
            end;
        end;

        if not f then begin
            item := lvPlugins.Items.Add;
            item.Caption := s;
            item.SubItems.Add( Options.ReadString('plugins', s+'_char', '' ));
            item.Checked := Options.ReadBool( 'plugins', s+'_chk', false );

            add_plug(AppPath + 'plugins\'+s);
        end;
    end;
    list.Free;

    // удалим те плагины которые не найдены
    while plist.Count > 0 do
        TPlugin( plist[0] ).Free;
    plist.Free;

    lvPlugins.Items.EndUpdate;
end;

procedure TfPlugins.btnSaveOrderClick(Sender: TObject);
var
i:integer;
begin
  if not Assigned(Options) then exit;

  Options.WriteInteger('plugins','count',lvPlugins.Items.Count);
  i := 0;
  while i < lvPlugins.Items.Count do
  begin
    Options.WriteString('plugins','name'+inttostr(i), lvPlugins.Items.Item[i].Caption);
    Options.WriteString('plugins','char'+inttostr(i), lvPlugins.Items.Item[i].SubItems[0]);
    Options.WriteBool('plugins','chk'+inttostr(i), lvPlugins.Items.Item[i].Checked);
    Inc(i);
  end;
  Options.UpdateFile;
end;

procedure TfPlugins.btnSetClick(Sender: TObject);
begin
    if (lvPlugins.ItemIndex >= 0) then
    if (not lvPlugins.Items[lvPlugins.ItemIndex].Checked) then
    begin
        lvPlugins.Items[lvPlugins.ItemIndex].SubItems[0] := edCharname.Text;
        Options.WriteString('plugins', lvPlugins.Items[lvPlugins.ItemIndex].Caption+'_char', edCharname.Text );
        TPlugin( lvPlugins.Items[lvPlugins.ItemIndex].Data ).CharName := edCharname.Text;
    end;
end;

procedure TfPlugins.btnUpClick(Sender: TObject);
var
  Index: integer;
  temp : TListItem;
begin
    if lvPlugins.SelCount>0 then
    begin
      Index := lvPlugins.Selected.Index;
      if Index>0 then
      begin
        temp := lvPlugins.Items.Insert(Index-1);
        temp.Assign(lvPlugins.Items.Item[Index+1]);
        lvPlugins.Items.Delete(Index+1);
        // fix display so moved item is selected/focused
        lvPlugins.Selected := temp;
        lvPlugins.ItemFocused := temp;

        btnSaveOrderClick(nil);
      end;
    end;
end;

procedure TfPlugins.FormCreate(Sender: TObject);
begin
    LoadControlPosition(Self);
    lvPlugins.DoubleBuffered := true;
end;

procedure TfPlugins.FormDestroy(Sender: TObject);
begin
    SaveControlPosition(Self);

    while Plugins.Count > 0 do
        TPlugin( Plugins[0] ).Free;
    Plugins.Free;
end;

procedure TfPlugins.Init;
begin
    Plugins := TList.Create;
    btnRefreshClick(nil);
end;

procedure TfPlugins.lvPluginsChange(Sender: TObject; Item: TListItem;
  Change: TItemChange);
begin
    if (Change = ctState) and (Item.Caption <> '') and (Options <> nil) then begin
        Options.WriteBool('plugins', item.Caption+'_chk', item.Checked);
        Options.UpdateFile;

        if (Item.Data <> nil) then begin
            if item.Checked then
                TPlugin( Item.Data ).Load
            else
                TPlugin( Item.Data ).Unload;
        end;
    end;
end;

procedure TfPlugins.lvPluginsClick(Sender: TObject);
begin
    if lvPlugins.ItemIndex >= 0 then
    edCharname.Text := lvPlugins.Items[lvPlugins.ItemIndex].SubItems[0];
end;

end.

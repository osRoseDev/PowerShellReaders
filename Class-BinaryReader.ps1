Class iRoseBinaryReader{
    
 #region Public Property Interface
    [Boolean]$Debug=$true
    [String]$LastBytes =""
    [String]$Filepath = ""

#endregion

 #region Private Property Interface
    hidden [System.IO.BinaryReader] $Stream=$null
 #endregion

 #region Consstructors
    iRoseBinaryReader(){}

    iRoseBinaryReader([String]$Path){
       if ([System.IO.File]::exists($path)){
            
            $this.Filepath = $path

            try{
                $this.Stream=New-Object System.IO.BinaryReader([System.IO.File]::Open($path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite))
            } catch {
                $this.Log("Open File", $_.Exception.Message)
                $this.Stream=null
            }
        }
     }
 #endregion

 #region interal methods
    hidden [void]Log($Action, $Value){

        if ($this.debug){
            $Callee = (Get-PSCallStack)[1].FunctionName
            $Callee = [string]$Callee.PadRight(15);

            $Action = [string]$action.PadRight(25);

            Write-Host "Function : $Callee" -ForegroundColor Yellow -noNewLine
            Write-Host $Action -ForegroundColor green -noNewLine
            Write-Host ($Value) -ForegroundColor gray
        }
    }
 #endregion

 #region public methods
        
#bStR  = String
#Word  = 16 bit unsigned number = 2 bytes = UINT16
#DWord = 32-bit unsigned number = 4 bytes = uint32
#Long  = 32-bit signed number = 4 bytes = int32

 [uInt32]Position(){
    if ($this.Stream){
        return $this.stream.BaseStream.Position
    } else {
        return 0
    }
 }

 [UInt16]ReadWORD(){
    [uInt32]$ret=0

    if ($this.Stream){
        #-- Only if we can read 2 more bytes.
        if ($this.Stream.basestream.position -le $this.Stream.baseStream.Length-2){
            $ret=$this.Stream.ReadUInt32()
        } else {
            $this.Log("ReadWORD", "No more bytes to read.")
            $ret=$null
        }
     }
     
     return $ret
 }
    
 [uInt32]ReadDWORD(){
    
    [uInt32]$ret=0

    if ($this.Stream){
        #-- Only if we can read 4 more bytes.
        if ($this.Stream.basestream.position -le $this.Stream.baseStream.Length-4){
            $ret=$this.Stream.ReadUInt32()
        } else {
            $this.Log("ReadDWORD", "No more bytes to read.")
            $ret=$null
        }
    }
        
    return $ret
 }

 [String]ReadBSTR(){
    #BStrings in iRoseOnline are defined as 
    #[Byte]Lenght;
    #[Char](Length]);

    $ret=$null
    if ($this.Stream){
        [int32]$len   = $this.Stream.ReadByte()
        [Byte[]]$Data = $this.Stream.ReadBytes($Len)

        #--Convert Bytes to String:
        $Ret = [System.Text.Encoding]::ASCII.GetString($Data)
    } else {
        $this.Log("ReadBSTR", "No Open File")
    }

    return $ret
 }
}

#endregion
  
$file = "F:\RoseDEV\PS STB STL\LIST_CLASS_S.STL"
#$file = "F:\RoseDEV\PS STB STL\STR_JOB.STL"
$file="F:\RoseDEV\PS STB STL\LIST_FACEITEM_S.STL"
$Reader = [iRoseBinaryReader]::New($file)

#-- Start Reading the STL File.
$STLType = $Reader.ReadBSTR()
$STLEntries = $Reader.ReadDWORD()

#-- Get Records
$Records=@()
For ($i=1;$i -le $STLEntries;$i++){
    $Record = New-Object -TypeName PSObject
    $Record | Add-Member -MemberType NoteProperty -Name StrID -value $Reader.ReadBSTR()
    $Record | Add-Member -MemberType NoteProperty -Name id -Value $Reader.ReadDWORD()
    $Records +=$Record
}

#-- Get Languages
$LangCount = $Reader.ReadDWORD()
$Languages = @()
for ($i=1; $i -le $LangCount; $i++){
    $LanguageTable = New-Object -TypeName PSObject
    $LanguageTable | Add-Member -MemberType NoteProperty -Name ID -Value $i
    $LanguageTable | Add-Member -MemberType NoteProperty -Name Offset -Value $Reader.ReadDWORD()

    $Languages+=$LanguageTable
}

Foreach ($languageTable in $Languages){
    $Reader.Stream.BaseStream.Position = $LanguageTable.Offset
    $ltRecords=@()

    Foreach ($Record in $Records){
        #-- We are now processing each language table.
        #-- The table has records, all ID+STR ID are the same.
        $Rec = New-Object -TypeName PSObject
        $Rec | Add-Member -MemberType NoteProperty -Name "ID" -Value $Record.ID
        $Rec | Add-Member -MemberType NoteProperty -Name "strID" -Value $Record.StrID
        $Rec | Add-Member -MemberType NoteProperty -Name "offset" -value $Reader.ReadDWORD()

        $ltRecords+=$Rec
    }

    #-- And add the Records to this language table.
    $LanguageTable | Add-Member -MemberType NoteProperty -Name Records -value $ltRecords
}

#-- Now we know all offsets and are able to fill each entry

Foreach ($languageTable in $Languages){
    Foreach ($Record in $LanguageTable.Records){
        $Reader.Stream.BaseStream.Position = $Record.Offset
        $Record | add-Member -MemberType NoteProperty -Name "Text" -Value $reader.ReadBSTR()

        if ($STLType-eq "QEST01" -or $STLType -eq "ITST01"){
            $Record | add-Member -MemberType NoteProperty -Name "Comment" -Value $reader.ReadBSTR()
        }
        if ($STLType-eq "QEST01"){
            $Record | add-Member -MemberType NoteProperty -Name "Quest1" -Value $reader.ReadBSTR()
            $Record | add-Member -MemberType NoteProperty -Name "Quest2" -Value $reader.ReadBSTR()
        }
    }
}



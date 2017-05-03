$file = "F:\RoseDEV\PS STB STL\LIST_CLASS_S.STL"
$file = "F:\RoseDEV\PS STB STL\STR_JOB.STL"

# See http://www.exploit-monday.com/2013/03/ParsingBinaryFileFormatsWithPowerShell.html

#Word  = 16 bit unsigned number = 2 bytes = UINT16
#DWord = 32-bit unsigned number = 4 bytes = uint32
#Long  = 32-bit signed number = 4 bytes = int32

Function Get-Position([System.IO.BinaryReader]$Stream){
    Write-Host "Position : $($Stream.BaseStream.Position)"
}
Function Read-DWord([System.IO.BinaryReader]$Stream){
#-- Read 2 bytes and return an uINT16
    [uInt32]$val = $Stream.ReadUInt32()
    Get-Position
    
    return $val
 
}
Function Read-Word([System.IO.BinaryReader]$Stream){
#-- Read 2 bytes and return an uINT16
    [uInt16]$val = $Stream.ReadUInt16()
    Get-Position -Stream $Stream
    return $val
}

Function Read-BSTR([System.IO.BinaryReader]$Stream){
    #BStrings in iRoseOnline are defined as 
        #[Byte]Lenght;
        #[Char](Length]);
    
    $len  = $Stream.ReadByte()
    [Byte[]]$Data = $Stream.ReadBytes($Len)

    Get-Position

    #--Convert Bytes to String:
    Return [System.Text.Encoding]::ASCII.GetString($Data)
}


$BinaryReader= New-Object System.IO.BinaryReader([System.IO.File]::Open($file, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite))
$BinaryReader.BaseStream.Position=0

$BIN = $BinaryReader

#-- Start Reading the STL File.
$STLType = Read-BSTR -Stream $BIN
$STLEntries = Read-DWord -Stream $BIN









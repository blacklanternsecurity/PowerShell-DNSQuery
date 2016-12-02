<# 
.SYNOPSIS 
    Sends a DNS query for an A record 
.DESCRIPTION 
    Currently only sends the UDP packet for the query.
    Was created for PowerShell 2 to help with directing a query to a custom DNS server.
.NOTES 
    Author:  Liam Glanfield - @OneLogicalMyth
.EXAMPLE
    Send-DNSQuery 192.168.1.1 google.co.uk
.LINK 
    https://github.com/OneLogicalMyth/PowerShell-DNSQuery
#>  

function Send-DNSQuery {
param($DNSServer=$false,$DomainName=$false)

    # check if values are present else return error
    if(-not $DNSServer)
    {
        Write-Error 'No DNS server was given, can not continue!'
        return $null
    }
    if(-not $DomainName)
    {
        Write-Error 'No domain name was given, can not continue!'
        return $null
    }

    # Define port and target IP address  
    $Port    = 53
    $Address = [system.net.IPAddress]::Parse( $DNSServer ) 
     
    # Create IP Endpoint  
    $End = New-Object System.Net.IPEndPoint $Address , $port  
     
    # Create Socket  
    $Saddrf   = [System.Net.Sockets.AddressFamily]::InterNetwork 
    $Stype    = [System.Net.Sockets.SocketType]::Dgram 
    $Ptype    = [System.Net.Sockets.ProtocolType]::UDP 
    $Sock     = New-Object System.Net.Sockets.Socket $saddrf , $stype , $ptype  
    $Sock.TTL = 26 
     
    # Connect to socket
    $sock.Connect( $end )  
    
    # create encoder 
    $Enc     = [System.Text.Encoding]::ASCII 
    
    # byte headers
    $header_begin = @(
                    #id
                    [byte]0x11, [byte]0x12,
                    #flags
                    [byte]0x01, [byte]0x00,
                    #quest
                    [byte]0x00, [byte]0x01,
                    #ansRR
                    [byte]0x00, [byte]0x00,
                    #autRR
                    [byte]0x00, [byte]0x00,
                    #addRR
                    [byte]0x00, [byte]0x00
    )
    $class = [byte]0x00, [byte]0x01
    $type  = [byte]0x00, [byte]0x01
    
    # we now explode on the full stops and replace them with length as a byte
    $buffer = $header_begin
    Foreach($Part in $DomainName.Split('.'))
    {
        $buffer = $buffer + ([byte]$Part.length) + $Enc.GetBytes( $Part )   
    }
    
    # add the class and type to the end
    $buffer = $buffer + [byte]0x00 + $class + $type

    # Send the buffer
    $Sent   = $Sock.Send( $buffer  ) 

}
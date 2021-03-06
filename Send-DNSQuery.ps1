<# 
.SYNOPSIS 
    Sends a DNS query for Variable record types
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
param($DNSServer=$false,$DomainName=$false, $DNSQueryType=$false)

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
    if(-not $DNSQueryType)
    {
        Write-Error 'No type given for query, can not continue!'
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
    # 0x00 0x01 = A
    # 0x00 0x02 = NS
    # 0x00 0x05 = CNAME
    # 0x00 0x06 = SOA
    # 0x00 0x10 = TXT
    # 0x00 0x0c = PTR
    # 0x00 0x0f = MX
    # 0x00 0x1c = AAAA
    if($DNSQueryType -eq 'A')
    {
        $type = [byte]0x00, [byte]0x01
    }
    if($DNSQueryType -eq 'NS')
    {
        $type = [byte]0x00, [byte]0x02
    }
    if($DNSQueryType -eq 'CNAME')
    {
        $type = [byte]0x00, [byte]0x05
    }
    if($DNSQueryType -eq 'SOA')
    {
        $type = [byte]0x00, [byte]0x06
    }
    if($DNSQueryType -eq 'TXT')
    {
        $type = [byte]0x00, [byte]0x10
    }
    if($DNSQueryType -eq 'PTR')
    {
        $type = [byte]0x00, [byte]0x0c
    }
    if($DNSQueryType -eq 'MX')
    {
        $type = [byte]0x00, [byte]0x0f
    }
    if($DNSQueryType -eq 'AAAA')
    {
        $type = [byte]0x00, [byte]0x1c
    }
    
    #Internet Class for Query
    $class  = [byte]0x00, [byte]0x01
    
    # we now explode on the full stops and replace them with length as a byte
    $buffer = $header_begin
    Foreach($Part in $DomainName.Split('.'))
    {
        $buffer = $buffer + ([byte]$Part.length) + $Enc.GetBytes( $Part )   
    }
    
    # add the class and type to the end
    #MTR - The $type and $class were mixed up. Should be $type first, then $class
    $buffer = $buffer + [byte]0x00 + $type + $class

    # Send the buffer
    $Sent   = $Sock.Send( $buffer  )

}
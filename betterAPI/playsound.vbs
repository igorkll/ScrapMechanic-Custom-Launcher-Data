set fso = CreateObject("Scripting.FileSystemObject")
set stdin = fso.GetStandardStream(0)

soundLoop = 0

With CreateObject("WMPlayer.OCX")
    .url = stdin.ReadLine()
    .settings.volume = 0

    do
        content = stdin.Read(1)

        if soundLoop = 1 then
            if .playState = 1 then
                .controls.play()
                WScript.Sleep 5
            end if
        end if

        if StrComp(content, "d") = 0 then
            exit do
        elseif StrComp(content, "v") = 0 then
            .settings.volume = (Asc(stdin.Read(1)) + Asc(stdin.Read(1))) / 2.55
        elseif StrComp(content, "b") = 0 then
            .settings.balance = (((Asc(stdin.Read(1)) + Asc(stdin.Read(1))) / 2.55) - 50) * 2
        elseif StrComp(content, "r") = 0 then
            .settings.rate = ((Asc(stdin.Read(1)) + Asc(stdin.Read(1))) + 1) / 64
        elseif StrComp(content, "1") = 0 then
            .controls.play()
        elseif StrComp(content, "0") = 0 then
            .controls.stop()
        elseif StrComp(content, "2") = 0 then
            .controls.pause()
        elseif StrComp(content, "5") = 0 then
            soundLoop = 1
        elseif StrComp(content, "6") = 0 then
            soundLoop = 0
        elseif StrComp(content, "p") = 0 then
            .controls.currentPosition = (Asc(stdin.Read(1)) + Asc(stdin.Read(1)))
        elseif StrComp(content, "s") = 0 then
            .controls.currentPosition = .controls.currentPosition + (Asc(stdin.Read(1)) + Asc(stdin.Read(1)))
        elseif StrComp(content, "S") = 0 then
            .controls.currentPosition = .controls.currentPosition - (Asc(stdin.Read(1)) + Asc(stdin.Read(1)))
        elseif StrComp(content, "E") = 0 then
            WScript.Sleep 5
        end if
    loop
End With
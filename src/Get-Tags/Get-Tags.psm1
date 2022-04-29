function get-tagValue {
    param (
        [string] $tagKey,
        [System.Object] $object
    )
        $tagString=get-tagstring($object)
        $tagslist=$tagString.split(";")
        foreach ($tag in $tagslist)
        {
            if ($tag.split("=")[0] -eq $tagKey)
            {
                return $tag.split("=")[1]
            }
        }
        return ""
    }
    function get-tagstring ($object)
    {
        if ($object.Tag.Count -eq 0)
        {
            $tagstring="None"
        }
        else
        {
            $tagstring=""
            $tKeys=$object.tag |Select-Object -ExpandProperty keys
            $tValues= $object.Tag | Select-Object -ExpandProperty values
            $index=0
            if ($object.Tag.Count -eq 1)
            {
                $tagstring="$tKeys=$tValues"
            }
            else 
            {
                foreach ($tkey in $tkeys)
                {
                    $tagstring+="$tkey=$($tValues[$index]);"
                    $index++
                }
            }
        }
        return $tagstring.Trim(";")
    }
    
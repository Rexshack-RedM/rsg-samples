RegisterNetEvent('rsg-samples:SampleData', function(SampleData)
    local pSrc = source
    local sampleHash = SampleData
    local sampleResult = RSG_ServerSampleHandler(pSrc, sampleHash)
    TriggerClientEvent('rsg-samples:Sampled', pSrc, sampleResult)
    if Config.DebugServer then
        print('[rsg-samples] SampleData', pSrc, sampleHash, sampleResult)
    end
end)
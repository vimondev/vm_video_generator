const sleep = ms => new Promise(resolve => setTimeout(resolve, ms))

const animMap = {}
const opentypeMap = {}

let isInitialized = false
window.addEventListener("flutterInAppWebViewPlatformReady", function (event) {
    console.log('flutter webview initialized!')
    isInitialized = true

    window.flutter_inappwebview.callHandler('TransferInit')
})

const LoadFont = async (fontFamliyArr, fontBase64) => {
    await Promise.all(fontFamliyArr.map((fontFamily, index) => {
        if (!opentypeMap[fontFamily]) {
            opentypeMap[fontFamily] = FontHelper.LoadOpenTypeFromBase64(fontBase64[index])
        }
        return FontHelper.LoadFontFamily(fontFamily, fontBase64[index])
    }))
}

const GetAnimAndSetText = async (id, json, texts) => {
    const sleep = ms => new Promise(resolve => setTimeout(resolve, ms))

    let anim
    if (animMap[id]) anim = animMap[id]
    else {
        anim = await LottieHelper.LoadAnimation(id, json)
        for (let i=0; i<300; i++) {
            if (anim.isDOMLoaded) break
            await sleep(100)
        }
        if (!anim.isDOMLoaded) {
            window.flutter_inappwebview.callHandler('TransferPreviewFailed')
            return null
        }

        animMap[id] = anim
    }
    
    texts.forEach((text, index) => {
        if (anim.textComps[index]) {
            anim.TextUpdate(anim.textComps[index], text)
        }
    })
}

const ExtractPreview = async ({ id, jobId, fontFamliyArr, fontBase64, json, texts }) => {
    const sleep = ms => new Promise(resolve => setTimeout(resolve, ms))
    if (!isInitialized) return

    try {
        const now = Date.now()
        
        await LoadFont(fontFamliyArr, fontBase64)
        const anim = await GetAnimAndSetText(id, json, texts)
        if (!anim) throw new Error("ERR_LOAD_FAILED")
    
        const { svgElement, allRect: { x, y, width, height } } = anim.CopySVGElement(anim.previewFrame, opentypeMap)
        window.flutter_inappwebview.callHandler('TransferPreviewPNGData', {
            width,
            height,
            frameRate: anim.animationData.fr,
            preview: await CanvasHelper.DrawPNG(svgElement, x, y, width, height),
            textData
        })
        console.log(`elapsed - : ${Date.now() - now}ms`)
    }
    catch (e) {
        console.log(e)
        window.flutter_inappwebview.callHandler('TransferPreviewFailed')
    }
}

const ExtractAllSequence = async ({ id, jobId, fontFamliyArr, fontBase64, json, texts }) => {
    if (!isInitialized) return

    try {
        const now = Date.now()

        await LoadFont(fontFamliyArr, fontBase64)
        const anim = await GetAnimAndSetText(id, json, texts)
        if (!anim) throw new Error("ERR_LOAD_FAILED")

        const svgElements = []

        let minX, minY, maxWidth = -1, maxHeight = -1
        for (let i = 0; i < anim.totalFrames; i++) {
            const { svgElement, allRect: { x, y, width, height } } = anim.CopySVGElement(anim.previewFrame, opentypeMap)

            if (width > maxWidth) {
                minX = x
                maxWidth = width
            }
            if (height > maxHeight) {
                minY = y
                maxHeight = height
            }

            svgElements.push(svgElement)
        }

        window.flutter_inappwebview.callHandler('TransferAllSequenceStart', {
            width: maxWidth,
            height: maxHeight,
            frameRate: anim.animationData.fr,
            totalFrameCount: anim.totalFrames
        })
    
        for (let i = 0; i < svgElements.length; i++) {
            const svg = svgElements[i]
            console.log(i, svgElements.length)
            
            window.flutter_inappwebview.callHandler('TransferAllSequencePNGData', {
                frameNumber: i,
                data: await CanvasHelper.DrawPNG(svg, x, y, width, height)
            })
        }

        window.flutter_inappwebview.callHandler('TransferAllSequenceComplete')
        console.log(`elapsed - : ${Date.now() - now}ms`)
    }
    catch (e) {
        console.log(e)
        window.flutter_inappwebview.callHandler('TransferAllSequenceFailed')
    }
}
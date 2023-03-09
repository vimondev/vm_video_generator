const _animMap = {}
const _opentypeMap = {}

let loadedJsonFilename
let loadedJson
let loadedFontFamily = []
let loadedFontBase64 = []

function loadJSON(file) {
    loadedFontFamily = []
    loadedJsonFilename = file.name
    const reader = new FileReader()
    reader.readAsText(file, 'utf8')
    reader.onload = e => {
        loadedJson = JSON.parse(e.target.result)
        if (loadedJson && loadedJson.fonts && Array.isArray(loadedJson.fonts.list)) {
            for (let i = 0; i < loadedJson.fonts.list.length; i++) {
                const { fFamily } = loadedJson.fonts.list[i]
                loadedFontFamily.push(fFamily)
            }
        }
    }
}

function loadFont(files) {
    for (let i = 0; i < files.length; i++) {
        const reader = new FileReader()
        const file = files[i]
        reader.readAsDataURL(file, 'utf8')
        reader.onload = e => {
            loadedFontBase64.push(e.target.result.split('base64,')[1])
        }
    }
}

function toggleUseDefaultText(e) {
    const textFieldWrapperDiv = document.getElementById("text-field-wrapper")
    if (e.target.checked) {
        textFieldWrapperDiv.style.visibility = 'hidden'
    }
    else {
        textFieldWrapperDiv.style.visibility = 'visible'
    }
}

window.onload = function () {
    document.getElementById("input-json").addEventListener('change', e => {
        loadJSON(e.target.files[0])
    })

    document.getElementById("input-font").addEventListener('change', e => {
        loadFont(e.target.files)
    })

    document.getElementById("use-default-text").addEventListener('click', toggleUseDefaultText)
}

const getIsUseDefaultText = () => document.getElementById("use-default-text").checked

const getText1Value = () => document.getElementById("input-text1").value
const getText2Value = () => document.getElementById("input-text2").value

const updateElapsedTime = value => {
    document.getElementById("elapsed-time").innerText = `${value}초`
}

const extractPreviewTest = async () => {
    const sleep = ms => new Promise(resolve => setTimeout(resolve, ms))
    const now = Date.now()

    try {
        await Promise.all(loadedFontFamily.map((fontFamily, index) => {
            _opentypeMap[fontFamily] = FontHelper.LoadOpenTypeFromBase64(loadedFontBase64[index])
            return FontHelper.LoadFontFamily(fontFamily, loadedFontBase64[index])
        }))
    }
    catch (e) {
        console.log(e)
    }

    let anim
    // if (_animMap[loadedJsonFilename]) anim = _animMap[loadedJsonFilename]
    // else 
    {
        anim = await LottieHelper.LoadAnimation(loadedJsonFilename, loadedJson)
        for (let i=0; i<300; i++) {
            if (anim.isDOMLoaded) break
            await sleep(100)
        }
        if (!anim.isDOMLoaded) {
            window.flutter_inappwebview.callHandler('TransferPreviewFailed')
            return null
        }

        _animMap[loadedJsonFilename] = anim
    }

    if (anim.textComps[0]) { 
        const compositionId = anim.textComps[0]
        if (!getIsUseDefaultText()) {
            anim.TextUpdate({
                compositionId,
                text: getText1Value()
            })
        }

        const box = anim.GetTextSize(compositionId)
        if (box && !isNaN(box.width) && box.width > anim.compWidth) {
            anim.TextUpdate({
                compositionId,
                scale: anim.compWidth / box.width
            })
        }
    }
    if (anim.textComps[1]) { 
        const compositionId = anim.textComps[1]
        if (!getIsUseDefaultText()) {
            anim.TextUpdate({
                compositionId,
                text: getText2Value()
            })
        }

        const box = anim.GetTextSize(compositionId)
        if (box && !isNaN(box.width) && box.width > anim.compWidth) {
            anim.TextUpdate({
                compositionId,
                scale: anim.compWidth / box.width
            })
        }
    }

    const { svgElement, allRect: { x, y, width, height }, allRect, previewData } = anim.CopySVGElement(anim.previewFrame, _opentypeMap)

    // const pngbase64 = await CanvasHelper.DrawPNG(svgElement, x, y, width, height, allRect, previewData)
    const pngbase64 = await CanvasHelper.DrawPNG(svgElement, x, y, width, height)

    const div = document.createElement('div')
    div.className = 'sequence-image-container'
    document.body.appendChild(div)
    
    const image = new Image()
    image.className = 'sequence-image'
    image.src = pngbase64
    div.appendChild(image)

    const guideDiv = document.createElement('div')
    guideDiv.className = 'sequence-guide'
    div.appendChild(guideDiv)

    anim.goToAndPlay(0, true)

    const elapsedTime = Date.now() - now
    updateElapsedTime(elapsedTime / 1000)

    console.log(`elapsed - : ${elapsedTime}ms`)
}

const extractAllSequenceTest = async () => {
    const sleep = ms => new Promise(resolve => setTimeout(resolve, ms))
    const now = Date.now()

    try {
        await Promise.all(loadedFontFamily.map((fontFamily, index) => {
            _opentypeMap[fontFamily] = FontHelper.LoadOpenTypeFromBase64(loadedFontBase64[index])
            return FontHelper.LoadFontFamily(fontFamily, loadedFontBase64[index])
        }))
    }
    catch (e) {
        console.log(e)
    }

    let anim
    // if (_animMap[loadedJsonFilename]) anim = _animMap[loadedJsonFilename]
    // else
    {
        anim = await LottieHelper.LoadAnimation(loadedJsonFilename, loadedJson)
        for (let i=0; i<300; i++) {
            if (anim.isDOMLoaded) break
            await sleep(100)
        }
        if (!anim.isDOMLoaded) {
            window.flutter_inappwebview.callHandler('TransferPreviewFailed')
            return null
        }

        _animMap[loadedJsonFilename] = anim
    }
    
    if (anim.textComps[0]) {
        const compositionId = anim.textComps[0]
        if (!getIsUseDefaultText()) {
            anim.TextUpdate({
                compositionId,
                text: getText1Value()
            })
        }

        const box = anim.GetTextSize(compositionId)
        if (box && !isNaN(box.width) && box.width > anim.compWidth) {
            anim.TextUpdate({
                compositionId,
                scale: anim.compWidth / box.width
            })
        }
    }
    if (anim.textComps[1]) {
        const compositionId = anim.textComps[1]
        if (!getIsUseDefaultText()) {
            anim.TextUpdate({
                compositionId,
                text: getText2Value()
            })
        }

        const box = anim.GetTextSize(compositionId)
        if (box && !isNaN(box.width) && box.width > anim.compWidth) {
            anim.TextUpdate({
                compositionId,
                scale: anim.compWidth / box.width
            })
        }
    }

    const svgElements = []
    const totalFrames = Math.min(anim.totalFrames, parseInt(anim.animationData.fr * 5))

    let minX = 0, minY = 0, maxWidth = -1, maxHeight = -1
    for (let i = 0; i < totalFrames; i++) {
        const { svgElement, allRect: { x, y, width, height } } = anim.CopySVGElement(i, _opentypeMap)

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
    
    for (let i = 0; i < svgElements.length; i++) {
        const svg = svgElements[i]
        console.log(i, svgElements.length)
        
        const pngbase64 = await CanvasHelper.DrawPNG(svg, minX, minY, maxWidth, maxHeight)        

        const div = document.createElement('div')
        div.className = 'sequence-image-container'
        document.body.appendChild(div)

        const image = new Image()
        image.className = 'sequence-image'
        image.src = pngbase64
        div.appendChild(image)

        const guideDiv = document.createElement('div')
        guideDiv.className = 'sequence-guide'
        div.appendChild(guideDiv)
    }

    anim.goToAndPlay(0, true)

    const elapsedTime = Date.now() - now
    updateElapsedTime(elapsedTime / 1000)

    console.log(`elapsed - : ${elapsedTime}ms`)
}
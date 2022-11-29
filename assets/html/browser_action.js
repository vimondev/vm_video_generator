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

window.onload = function () {
    const jsonEl = document.getElementById("input-json")
    jsonEl.addEventListener('change', e => {
        loadJSON(e.target.files[0])
    })

    const fontEl = document.getElementById("input-font")
    fontEl.addEventListener('change', e => {
        loadFont(e.target.files)
    })
}

let test = 0

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
    console.log(_opentypeMap)

    let anim
    if (_animMap[loadedJsonFilename]) anim = _animMap[loadedJsonFilename]
    else {
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

    if (anim.textComps[0]) anim.TextUpdate(anim.textComps[0], 'THIS IS TITLE' + test++)
    if (anim.textComps[1]) anim.TextUpdate(anim.textComps[1], 'THIS IS SUBTITLE' + test++)

    const { svgElement, allRect: { x, y, width, height }, allRect, previewData } = anim.CopySVGElement(anim.previewFrame, _opentypeMap)

    const pngbase64 = await CanvasHelper.DrawPNG(svgElement, x, y, width, height, allRect, previewData)

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

    console.log(anim.goToAndPlay)
    anim.goToAndPlay(0, true)

    console.log(`elapsed - : ${Date.now() - now}ms`)
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
    console.log(_opentypeMap)

    let anim
    if (_animMap[loadedJsonFilename]) anim = _animMap[loadedJsonFilename]
    else {
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
    
    if (anim.textComps[0]) anim.TextUpdate(anim.textComps[0], 'THIS IS TITLE')
    if (anim.textComps[1]) anim.TextUpdate(anim.textComps[1], 'THIS IS SUBTITLE')

    const svgElements = []
    let minX = 0, minY = 0, maxWidth = -1, maxHeight = -1
    for (let i = 0; i < anim.totalFrames; i++) {
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

    console.log(`elapsed - : ${Date.now() - now}ms`)
}
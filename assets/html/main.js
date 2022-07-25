    let anim
    let openTypeFont = []

    let currentFontFamily = []
    let currentFontFilename = []
    let currentFontBase64 = []
    let currentJson = {}

    let loadedFontFamily = []
    let loadedFontFilename = []
    let loadedFontBase64 = []
    let loadedJson = ''

    let previewFrameNumber = 0
    let previewData = {}
    let gridData = {}
    let textData = []
    let boundingBoxTexts = []
    let prevTime = 0
    let svgX = 0
    let svgY = 0
    let gElement
    let gWidth = 0
    let gHeight = 0
    let textComps
    let styleList = []

    const space = 200

    const sleep = ms => new Promise(resolve => setTimeout(resolve, ms))

    function base64ToArrayBuffer(base64) {
        var binary_string = atob(base64)
        var len = binary_string.length
        var bytes = new Uint8Array(len)
        for (var i = 0; i < len; i++) {
            bytes[i] = binary_string.charCodeAt(i)
        }
        return bytes.buffer
    }

    function loadJSON(file) {
        loadedFontFamily = []
        const reader = new FileReader()
        reader.readAsText(file, 'utf8')
        reader.onload = e => {
            loadedJson = JSON.parse(e.target.result)
            if (loadedJson && loadedJson.fonts && Array.isArray(loadedJson.fonts.list)) {
                for (let i = 0; i < loadedJson.fonts.list.length; i++) {
                    const { fFamily } = loadedJson.fonts.list[i]
                    loadedFontFamily.push(fFamily)
                }
                // alert('font-family : ' + loadedFontFamily.join(', '))
            }
        }
    }

    function loadFont(files) {
        loadedFontFilename = []
        for (let i = 0; i < files.length; i++) {
            const reader = new FileReader()
            const file = files[i]
            loadedFontFilename.push(file.name)
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

    async function setData({ fontFamily, base64, json, texts }) {
        let sleepCount = 1;
        while (!isInitialized) {
            sleepCount++
            await sleep(200)
            if (sleepCount > 10) return
        }

        const fontBase64 = base64
        console.log(`setData is called..`)
        currentFontFamily = fontFamily
        currentFontFilename = []
        currentFontBase64 = fontBase64
        currentJson = json
        boundingBoxTexts = texts
        openTypeFont = []

        //const elements1 = document.getElementsByClassName("lottie-for-font-load-temporary-tags")
        //while (elements1.length > 0) {
        //    elements1[0].parentNode.removeChild(elements1[0])
        //}

        //const elements2 = document.getElementsByClassName("font-tags")
        //while (elements2.length > 0) {
        //    elements2[0].parentNode.removeChild(elements2[0])
        //}

        for (let i = 0; i < currentFontBase64.length; i++) {
            openTypeFont.push(opentype.parse(base64ToArrayBuffer(currentFontBase64[i])))
        }

        while (styleList.length > 0) {
            const s = styleList.pop()
            document.head.removeChild(s)
        }

        for (let i = 0; i < currentFontFamily.length; i++) {
            const styleEl = document.createElement('style')
            styleEl.className = `font-tags`
            // styleEl.innerHTML = `
            //     @font-face {
            //         font-family: ${currentFontFamily[i]};
            //         src: url("${currentFontFilename[i]}");
            //     }
            // `
            styleEl.innerHTML = `
                @font-face {
                    font-family: ${currentFontFamily[i]};
                    src: url(data:application/font-woff;charset=utf-8;base64,${currentFontBase64[i]});
                }
            `

            document.head.appendChild(styleEl)
            styleList.push(styleEl)

            const div = document.createElement('div')
            div.className = `lottie-for-font-load-temporary-tags`
            div.style.position = 'absolute'
            div.style.left = '-99999px'
            div.style.fontFamily = currentFontFamily[i]
            div.style.visibility = 'hidden'
            div.innerText = currentFontFamily[i]
            document.body.appendChild(div)

            // 최대 60초동안 로드
            for (let x = 0; x < 100; x++) {
                await sleep(100)
                console.log(currentFontFamily[i], document.fonts.check(`12px ${currentFontFamily[i]}`))
                if (document.fonts.check(`12px ${currentFontFamily[i]}`)) break
            }
        }

        const { assets, layers } = currentJson
        const textCompMap = {}

        console.log('111111111111111111111111');

        assets.forEach(item => {
            if (item.nm && typeof item.nm === 'string' && item.nm.toLowerCase().startsWith('#text')) {
                textCompMap[item.nm] = item
            }
        })
        layers.forEach(item => {
            if (item.nm && typeof item.nm == 'string' && item.nm.toLowerCase().startsWith('@preview')) {
                previewFrameNumber = parseInt(item.ip)
            }
        })

        console.log('222222222222222222222222');
        textComps = Object.keys(textCompMap)
        textComps.sort((a, b) => a > b ? 1 : a < b ? -1 : 0)
        console.log(textComps.join('\n'))
        console.log(textCompMap)

        const replaceText = (layers, text) => {
            let originalText = ''
            if (!text) text = ''

            for (let i = 0; i < layers.length; i++) {
                const layer = layers[i]
                if (layer.nm === '@Source') {
                    originalText = String(layer.t.d.k[0].s.t)
                    layer.t.d.k[0].s.t = text
                    console.log(layer)
                    break
                }
            }
            layers.forEach(layer => {
                if (layer.t &&
                    layer.t.d &&
                    layer.t.d.k &&
                    layer.t.d.k[0] &&
                    layer.t.d.k[0].s &&
                    layer.t.d.k[0].s.t &&
                    layer.t.d.k[0].s.t === originalText
                ) {
                    layer.t.d.k[0].s.t = text
                }
            })
        }
        textComps.forEach((name, index) => {
            replaceText(textCompMap[name].layers, texts[index])
        })
    }

    let isInitialized = false
    window.addEventListener("flutterInAppWebViewPlatformReady", function (event) {
        console.log('flutter webview initialized!')
        isInitialized = true

        if (window.flutter_inappwebview) {
            window.flutter_inappwebview.callHandler('TransferInit')
        }
    })

    async function extractPreview() {
        if (!isInitialized) return

        const images = document.getElementsByTagName('img');
        while(images.length > 0) {
            images[0].parentNode.removeChild(images[0]);
        }

        // setData({
        //     fontFamily: loadedFontFamily,
        //     fontFilename: loadedFontFilename,
        //     fontBase64: loadedFontBase64,
        //     json: loadedJson,
        //     texts: [ 'THIS IS VIMON', 'FANCY-TITLE!!' ]
        // })
        runPreview()
    }

    async function extractAllSequence() {
        if (!isInitialized) return

        const images = document.getElementsByTagName('img');
        while(images.length > 0) {
            images[0].parentNode.removeChild(images[0]);
        }

        // setData({
        //     fontFamily: loadedFontFamily,
        //     fontFilename: loadedFontFilename,
        //     fontBase64: loadedFontBase64,
        //     json: loadedJson,
        //     texts: [ 'THIS IS VIMON', 'FANCY-TITLE!!' ]
        // })
        runAll()
    }

    const AssignFrameNumber = (node, index) => {
        if (node.attributes) {
            for (let i = 0; i < node.attributes.length; i++) {
                const attribute = node.attributes[i]
                attribute.value = attribute.value.replace(/__lottie_element/gi, `__lottie_element_frame_${index}`)
            }
        }
        for (let i = 0; i < node.childNodes.length; i++) {
            AssignFrameNumber(node.childNodes[i], index)
        }
        return node
    }

    const ResetUnusedDefs = defsNode => {
        if (defsNode.hasChildNodes()) {
            defsNode.childNodes.forEach(childNode => {
                if (childNode.tagName === 'filter' && childNode.getAttribute('filterUnits') === 'objectBoundingBox') {
                    childNode.removeAttribute('x')
                    childNode.removeAttribute('y')
                    childNode.removeAttribute('width')
                    childNode.removeAttribute('height')
                }
                else if (childNode.tagName === 'text') {
                    childNode.remove()
                }
            })
        }
    }

    const convertTextToPath = (node, textElements = []) => {
        const findParent = node => {
            if (node.hasAttribute('font-family')) return node
            else if (node.parentNode) {
                return findParent(node.parentNode)
            }
        }
        const findTextValue = node => {
            if (node.hasChildNodes()) {
                let value = ''
                node.childNodes.forEach(childNode => {
                    if (!value) {
                        value = findTextValue(childNode)
                    }
                })
                return value
            }
            else return node.innerHTML ? node.innerHTML : node.nodeValue
        }
        if (node.tagName === 'text') {
            const parent = findParent(node)
            if (!parent) return

            const value = findTextValue(node) || ''
            const textAnchor = node.getAttribute("text-anchor")
            const fill = parent.getAttribute("fill")
            const fontSize = Number(parent.getAttribute("font-size"))
            const fontFamily = parent.getAttribute('font-family')
            let OTF = openTypeFont[0]
            let path = OTF.getPath(value, 0, 0, fontSize)

            for (let i = 0; i < currentFontFamily.length; i++) {
                if (currentFontFamily[i] === fontFamily) {
                    OTF = openTypeFont[i]
                    path = OTF.getPath(value, 0, 0, fontSize)
                    break
                }
            }

            if (textAnchor) {
                const { x1, x2 } = path.getBoundingBox()
                const width = x2 - x1

                let calculatedX = 0

                switch (textAnchor) {
                    case 'middle':
                        calculatedX -= (width / 2)
                        break

                    case 'end':
                        calculatedX -= width
                        break

                    case 'start':
                    default:
                        break
                }
                path = OTF.getPath(value, calculatedX, 0, fontSize)
            }

            const pathElement = path.toDOMElement()
            if (node.attributes) {
                for (let i = 0; i < node.attributes.length; i++) {
                    const attribute = node.attributes[i]
                    pathElement.setAttribute(attribute.name, attribute.value)
                }
            }
            pathElement.setAttribute("fill", fill)
            node.parentNode.appendChild(pathElement)
            textElements.push(node)
        }
        else if (node.hasChildNodes()) {
            node.childNodes.forEach(node => {
                convertTextToPath(node, textElements)
            })
        }
        return textElements
    }

    function DrawPNG(svgElement, anim, x, y, idx, isPreview) {
        return new Promise((resolve, reject) => {
            const image = new Image()
            const src = 'data:image/svg+xml,' + encodeURIComponent((new XMLSerializer).serializeToString(svgElement))
            image.onload = function (e) {
                const canvas = document.createElement('canvas')
                const ctx = canvas.getContext('2d')
                canvas.width = gWidth
                canvas.height = gHeight

                ctx.drawImage(image, x, y, gWidth, gHeight, 0, 0, gWidth, gHeight)

                if (isPreview && previewData && previewData.data && previewData.data.length > 0) {
                    textData = []
                    previewData.data.forEach(function (item, index) {
                        const rectX = (previewData.data[index].rect.x - gridData.x) - 10
                        const rectY = (previewData.data[index].rect.y - gridData.y) - 10
                        const rectWidth = previewData.data[index].rect.width + 20
                        const rectHeight = previewData.data[index].rect.height + 20
                        textData.push({
                            key: item.key,
                            value: boundingBoxTexts[index],
                            x: rectX,
                            y: rectY,
                            width: rectWidth,
                            height: rectHeight
                        })
                        // ctx.globalAlpha = 0.2
                        // ctx.fillRect(rectX, rectY, rectWidth, rectHeight)
                    })
                }

                resolve(canvas.toDataURL('image/png'))
            }
            image.onerror = function (e) {
                reject(e)
            }
            image.src = src
        })
    }

    let isRunning = false

  setNodeMaskClipPath = (node, isText) => {
    if (!node.nodeValue) {
      const id = node.getAttribute('id')
      if (!isText && id && id.toLowerCase().startsWith('text')) {
          isText = true
      }
      if (isText) {
        if (node.getAttribute('clip-path')) {
            node.setAttribute('clip-path', '')
        }
        if (node.getAttribute('mask')) {
            node.setAttribute('mask', '')
        }
      }
    }

    if (node.hasChildNodes()) {
      node.childNodes.forEach(childNode => {
        setNodeMaskClipPath(childNode, isText)
      })
    }
  }

    async function runPreview() {
        if (isRunning) return
        if (!isInitialized) return

        previewData = {}
        gridData = {}
        prevTime = 0
        gWidth = 0
        gHeight = 0
        textData = []

        if (anim) {
            anim.destroy()
        }

        anim = bodymovin.loadAnimation({
            container: document.getElementById('bodymovin'),
            renderer: 'svg',
            loop: false,
            autoplay: false,
            animationData: currentJson
        })

        let currentFrame = 0
        anim.addEventListener('DOMLoaded', async function (e) {
            try {
                const list = []
                const now = Date.now()

                bodymovin.goToAndStop(previewFrameNumber, true)

                const rootSVGElement = anim.renderer.svgElement.cloneNode(false)
                rootSVGElement.style.width = ''
                rootSVGElement.style.height = ''

                anim.renderer.svgElement.childNodes.forEach(node => {
                    switch (node.tagName) {
                        case 'defs': {
                            const defsEl = AssignFrameNumber(node.cloneNode(true), previewFrameNumber)
                            ResetUnusedDefs(defsEl)
                            rootSVGElement.appendChild(defsEl)
                        }
                            break

                        case 'g': {
                            setNodeMaskClipPath(node, false)

                            const gEl = node.cloneNode(true)
                            const textElements = convertTextToPath(gEl)
                            textElements.forEach(element => element.remove())

                            gElement = gEl
                            rootSVGElement.appendChild(AssignFrameNumber(gEl, previewFrameNumber))
                        }
                            break
                    }
                })
                if (gElement) {
                    const tempsvg = document.body.querySelector('#tempsvg')
                    tempsvg.appendChild(rootSVGElement)

                    const svgBoundingBox = rootSVGElement.getBoundingClientRect()
                    const gBoundingBox = gElement.getBoundingClientRect()

                    if (gBoundingBox.width + space > gWidth) {
                        gWidth = Math.min(gBoundingBox.width + space, svgBoundingBox.width)
                        gridData.width = gWidth
                        gridData.x = (anim.animationData.w - gWidth) / 2
                    }
                    if (gBoundingBox.height + space > gHeight) {
                        gHeight = Math.min(gBoundingBox.height + space, svgBoundingBox.height)
                        gridData.height = gHeight
                        gridData.y = (anim.animationData.h - gHeight) / 2
                    }

                    // PREVIEW의 데이터 뽑기
                    previewData["data"] = []
                    textComps.forEach((name, index) => {
                        const TEXTBOX = rootSVGElement.querySelector(`g#${name.replace("#", "")}`)
                        const rect = {}

                        const textBoundingBox = TEXTBOX.getBoundingClientRect()

                        rect.x = textBoundingBox.x - svgBoundingBox.x
                        rect.y = textBoundingBox.y - svgBoundingBox.y
                        rect.width = textBoundingBox.width
                        rect.height = textBoundingBox.height

                        if (TEXTBOX) {
                            previewData["data"].push({ key: name, rect: rect })
                        }
                    })
                    tempsvg.removeChild(rootSVGElement)
                }
                list.push(rootSVGElement)

                if (window.flutter_inappwebview) {
                    window.flutter_inappwebview.callHandler('TransferPreviewPNGData', {
                        width: gWidth,
                        height: gHeight,
                        frameRate: anim.animationData.fr,
                        preview: await DrawPNG(list[0], anim, gridData.x, gridData.y, 0, true),
                        textData
                    })
                }
                const elapsed = Date.now() - now
                console.log(`elapsed - : ${elapsed}ms`)

                if (elapsed >= 500) {
                    throw new Error("ERR_HEAVY")
                }
            }
            catch (e) {
                console.log(String(e))
                bodymovin.destroy()
                isRunning = false

                if (window.flutter_inappwebview) {
                    window.flutter_inappwebview.callHandler('TransferPreviewFailed')
                }
            }
        })
    }

    async function runAll() {
        if (isRunning) return
        if (!isInitialized) return

        previewData = {}
        gridData = {}
        prevTime = 0
        gWidth = 0
        gHeight = 0
        textData = []

        if (anim) {
            anim.destroy()
        }

        anim = bodymovin.loadAnimation({
            container: document.getElementById('bodymovin'),
            renderer: 'svg',
            loop: false,
            autoplay: false,
            animationData: currentJson
        })

        let currentFrame = 0
        anim.addEventListener('DOMLoaded', async function (e) {
            try {
                const list = []
                const now = Date.now()

                for (let i = 0; i < anim.totalFrames; i++) {
                    bodymovin.goToAndStop(i, true)

                    const rootSVGElement = anim.renderer.svgElement.cloneNode(false)
                    rootSVGElement.style.width = ''
                    rootSVGElement.style.height = ''

                    anim.renderer.svgElement.childNodes.forEach(node => {
                        switch (node.tagName) {
                            case 'defs': {
                                const defsEl = AssignFrameNumber(node.cloneNode(true), i)
                                ResetUnusedDefs(defsEl)
                                rootSVGElement.appendChild(defsEl)
                            }
                            break

                            case 'g': {
                                setNodeMaskClipPath(node, false)

                                const gEl = node.cloneNode(true)
                                const textElements = convertTextToPath(gEl)
                                textElements.forEach(element => element.remove())

                                gElement = gEl
                                rootSVGElement.appendChild(AssignFrameNumber(gEl, i))
                            }
                            break
                        }
                    })
                    if (gElement) {
                        const tempsvg = document.body.querySelector('#tempsvg')
                        tempsvg.appendChild(rootSVGElement)

                        const svgBoundingBox = rootSVGElement.getBoundingClientRect()
                        const gBoundingBox = gElement.getBoundingClientRect()

                        if (gBoundingBox.width + space > gWidth) {
                            gWidth = Math.min(gBoundingBox.width + space, svgBoundingBox.width)
                            gridData.width = gWidth
                            gridData.x = (anim.animationData.w - gWidth) / 2
                        }
                        if (gBoundingBox.height + space > gHeight) {
                            gHeight = Math.min(gBoundingBox.height + space, svgBoundingBox.height)
                            gridData.height = gHeight
                            gridData.y = (anim.animationData.h - gHeight) / 2
                        }

                        tempsvg.removeChild(rootSVGElement)
                    }
                    list.push(rootSVGElement)
                }

                if (window.flutter_inappwebview) {
                    window.flutter_inappwebview.callHandler('TransferAllSequenceStart', {
                        width: gWidth,
                        height: gHeight,
                        frameRate: anim.animationData.fr,
                        totalFrameCount: anim.totalFrames
                    })
                    for (let i = 0; i < list.length; i++) {
                        const svg = list[i]
                        console.log(i, list.length)
                        
                        window.flutter_inappwebview.callHandler('TransferAllSequencePNGData', {
                            frameNumber: i,
                            data: await DrawPNG(svg, anim, gridData.x, gridData.y, i, false)
                        })
                    }
                    await sleep(1000)

                    window.flutter_inappwebview.callHandler('TransferAllSequenceComplete')
                }
                console.log(`elapsed - : ${Date.now() - now}ms`)
            }
            catch (e) {
                console.log(String(e))
                bodymovin.destroy()
                isRunning = false

                if (window.flutter_inappwebview) {
                    window.flutter_inappwebview.callHandler('TransferAllSequenceFailed')
                }
            }
        })
    }
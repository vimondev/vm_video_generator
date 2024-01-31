const { bodymovin } = window

const RemoveMasks = (node, isText) => {
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
            RemoveMasks(childNode, isText)
        })
    }
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

const ConvertTextToPath = (node, opentypeMap, textElements = []) => {
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
        
        const OTF = opentypeMap[fontFamily] || opentypeMap[Object.keys(opentypeMap)[0]]
        let path = OTF.getPath(value, 0, 0, fontSize)

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
            ConvertTextToPath(node, opentypeMap, textElements)
        })
    }
    return textElements
}

const FixTextLayer = animationData => {
    const { assets } = animationData
    assets.forEach(item => {
        let compName = ''
        if (typeof item.nm === 'string' && item.nm.toLowerCase().startsWith('#text')) {
            compName = item.nm
        }

        if (Array.isArray(item.layers)) {
            item.layers.forEach(layer => {
                if (typeof layer.nm === 'string') {
                    let isTextLayer = false
                    if (layer.nm.toLowerCase().startsWith('@source')) isTextLayer = true
                    if (layer.t && layer.t.d && typeof layer.t.d.x === 'string' && layer.t.d.x.includes('text.sourceText')) {
                        if (!compName) {
                            let currentExpression = layer.t.d.x
                            let startIndex = currentExpression.indexOf('comp(\'')
                            if (startIndex !== -1) {
                                currentExpression = currentExpression.substr(startIndex + 6, currentExpression.length)
                                let endIndex = currentExpression.indexOf('\')')
                                if (endIndex !== -1) {
                                    currentExpression = currentExpression.substr(0, endIndex)
                                    if (typeof currentExpression === 'string' && currentExpression.toLowerCase().startsWith('#text')) {
                                        compName = currentExpression
                                        item.nm = currentExpression
                                    }
                                }
                            }
                        }
    
                        delete layer.t.d.x
                        layer.nm = '@Source'
                        isTextLayer = true
                    }
    
                    if (isTextLayer) {
                        layer.compName = compName
                    }
                }
            })
        }
    })
}

const LoadAnimation = async (id, animationData) => {
    const containerRef = document.createElement('div')
    containerRef.className = 'lottie-container'
    containerRef.id = id
    document.body.appendChild(containerRef)

    FixTextLayer(animationData)

    const anim = bodymovin.loadAnimation({
        container: containerRef,
        animationData: animationData,
        renderer: 'svg',
        loop: false,
        autoplay: false
    })
    anim.id = id
    anim.isDOMLoaded = false
    anim.previewFrame = 0
    anim.GetTextSize = GetTextSize
    anim.TextUpdate = TextUpdate
    anim.CopySVGElement = CopySVGElement
    anim.Release = Release
    anim.opentype = {}
    anim.textMap = {}

    anim.addEventListener('DOMLoaded', async function (e) {
        anim.isDOMLoaded = true
        const { animationData: { assets, layers } } = anim

        const textCompMap = {}
        assets.forEach(item => {
            if (item.nm && typeof item.nm === 'string' && item.nm.toLowerCase().startsWith('#text')) {
                textCompMap[item.nm] = item
            }
        })
        anim.textComps = Object.keys(textCompMap)
        anim.textComps.sort((a, b) => a > b ? 1 : a < b ? -1 : 0)

        anim.compWidth = anim.renderer.data.w
        anim.compHeight = anim.renderer.data.h

        for (let i = 0; i < layers.length; i++) {
            const { nm, ip } = layers[i]
            if (nm.toLowerCase() === '@preview') {
                anim.previewFrame = ip
                anim.goToAndStop(ip, true)
            }
        }

        anim.textComps.forEach(compositionId => {
            const textLayers = GetTextSourceLayers(anim, compositionId)
            if (Array.isArray(textLayers)) {
                textLayers.forEach(textLayer => {
                    const layer = textLayer.data
                    if (layer.t && layer.t.d && layer.t.d.k && layer.t.d.k[0] && layer.t.d.k[0].s) {
                        anim.textMap[compositionId] = layer.t.d.k[0].s.t
                        textLayer.originalFontSize = layer.t.d.k[0].s.s
                    }
                })
            }
        })
    })

    return anim
}

const GetTextSourceLayers = (anim, compositionId) => {
    compositionId = compositionId.toLowerCase()

    const findTextLayerElements = (compositionId, currentElements, textLayerElements = []) => {
        for (let i=0; i<currentElements.length; i++) {
            const currentElement = currentElements[i]
            const { data: { nm: sourceNm, compName }, elements } = currentElement
            if (Array.isArray(elements)) {
                findTextLayerElements(compositionId, elements, textLayerElements)
            }
            else {
                if (typeof sourceNm === 'string'
                    && typeof compName === 'string'
                    && compName.toLowerCase() === compositionId
                    && sourceNm.toLowerCase().startsWith('@source')
                    && typeof currentElement.updateDocumentData === 'function') {
                        textLayerElements.push(currentElement)
                }
            }
        }
        return textLayerElements
    }

    return findTextLayerElements(compositionId, anim.renderer.elements)
}

function GetTextSize(compositionId) {
    const anim = this

    if (!anim) return null
    if (!anim.isDOMLoaded) return null    

    let maxWidth = -1, maxHeight = -1
    const texyLayers = GetTextSourceLayers(anim, compositionId)
    texyLayers.forEach(textLayer => {
        const element = textLayer.baseElement || textLayer.layerElement
        const boundingBox = element.getBoundingClientRect()

        if (boundingBox.width > maxWidth) maxWidth = boundingBox.width
        if (boundingBox.height > maxHeight) maxHeight = boundingBox.height
    })

    return { width: maxWidth * 1.1, height: maxHeight * 1.1 }
}

function TextUpdate({ compositionId, text = '', scale = 1, letterSpacing = 1 }) {    
    const anim = this

    if (!anim) return
    if (!anim.isDOMLoaded) return
    
    if (typeof text === 'string' && text.length > 0) {
        anim.textMap[compositionId] = text
    }

    const textSourceLayerElements = GetTextSourceLayers(anim, compositionId)

    textSourceLayerElements.forEach(element => {
        const updateObj = { t: anim.textMap[compositionId], tr: parseInt(60 * letterSpacing) }
        if (scale <= 1) {
            updateObj.s = Math.floor(element.originalFontSize * scale)
        }
        element.updateDocumentData(updateObj)
    })

    const previewFrame = anim.previewFrame || 0
    anim.goToAndStop(previewFrame + 1, true)
    anim.goToAndStop(previewFrame, true)
}

function CopySVGElement(frameNumber, opentypeMap, preview) {
    const anim = this

    if (!anim) return
    if (!anim.isDOMLoaded) return

    anim.goToAndStop(frameNumber + 1, true)
    anim.goToAndStop(frameNumber, true)

    const svgElement = anim.renderer.svgElement.cloneNode(false)
    svgElement.style.width = ''
    svgElement.style.height = ''

    let gElement
    anim.renderer.svgElement.childNodes.forEach(node => {
        switch (node.tagName) {
            case 'defs': {
                const defsEl = AssignFrameNumber(node.cloneNode(true), frameNumber)
                ResetUnusedDefs(defsEl)
                svgElement.appendChild(defsEl)
            }
                break

            case 'g': {
                RemoveMasks(node, false)
                
                const gEl = node.cloneNode(true)
                const textElements = ConvertTextToPath(gEl, opentypeMap)
                textElements.forEach(element => element.remove())

                gElement = gEl
                svgElement.appendChild(AssignFrameNumber(gEl, frameNumber))
            }
                break
        }
    })

    const space = 200
    const allRect = { x: 0, y: 0, width: 1, height: 1 }
    const previewData = { data: [] }
    const textBoundingBox = {}

    if (gElement) {
        const tempsvg = document.body.querySelector('#tempsvg')
        tempsvg.appendChild(svgElement)

        const svgBoundingBox = svgElement.getBoundingClientRect()
        const gBoundingBox = gElement.getBoundingClientRect()

        allRect.width = Math.min(gBoundingBox.width + space, svgBoundingBox.width)
        allRect.height = Math.min(gBoundingBox.height + space, svgBoundingBox.height)

        allRect.x = (anim.animationData.w - allRect.width) / 2
        allRect.y = (anim.animationData.h - allRect.height) / 2

        // PREVIEW의 데이터 뽑기
        anim.textComps.forEach(name => {
            const TEXTBOX = svgElement.querySelector(`g#${name.replace("#", "")}`)
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

        anim.renderer.svgElement.childNodes.forEach(node => {
            switch (node.tagName) {
                case 'g': {
                    if (!preview || preview.type === 0) {
                        // Calculate the rectangle that surrounds both texts.
                        const textCombined = { yMin: 100000, yMax: 0, height: 1 }

                        node.childNodes.forEach(node => {
                            if (anim.textComps.includes(`#${node.id}`)) {
                                // The bounding box for each text.
                                const boundingBox = node.getBoundingClientRect()
                                // Get the minimum y of all texts. This is the y position at the top of the text.
                                textCombined.yMin = Math.min(textCombined.yMin, boundingBox.y)
                                // Get the maximum y of all texts. This is the y position at the bottom of the text.
                                textCombined.yMax = Math.max(textCombined.yMax, boundingBox.y + boundingBox.height)
                            }
                        })

                        // Calculate the combined height of all texts.
                        textCombined.height = textCombined.yMax - textCombined.yMin

                        node.childNodes.forEach(node => {
                            if (anim.textComps.includes(`#${node.id}`)) {
                                const boundingBox = node.getBoundingClientRect()
                                // This is the y center for all texts.
                                const baseY = textCombined.height / 2
                                
                                // Calculate how far away each text is from the y center.
                                const difference = boundingBox.y - textCombined.yMin

                                textBoundingBox[`#${node.id}`] = {
                                    x: (preview ? preview.xShift : 0) + Math.floor(allRect.width + 2) / 2 - boundingBox.width / 2,
                                    y: (preview ? preview.yShift : 0) + Math.floor(allRect.height + 2) / 2 - baseY + difference,
                                    width: boundingBox.width,
                                    height: boundingBox.height,
                                }
                            }
                        })
                    } else if (preview.type === 1) {
                        // Calculate the rectangle that surrounds both texts.
                        const textCombined = { yMin: 100000, yMax: 0, height: 1 }

                        node.childNodes.forEach(node => {
                            if (anim.textComps.includes(`#${node.id}`)) {
                                // The bounding box for each text.
                                const boundingBox = node.getBoundingClientRect()
                                // Get the minimum y of all texts. This is the y position at the top of the text.
                                textCombined.yMin = Math.min(textCombined.yMin, boundingBox.y)
                                // Get the maximum y of all texts. This is the y position at the bottom of the text.
                                textCombined.yMax = Math.max(textCombined.yMax, boundingBox.y + boundingBox.height)
                            }
                        })

                        // Calculate the combined height of all texts.
                        textCombined.height = textCombined.yMax - textCombined.yMin

                        node.childNodes.forEach(node => {
                            if (!anim.textComps.includes(`#${node.id}`)) {
                                node.childNodes.forEach((node, i) => {
                                    const boundingBox = node.getBoundingClientRect()
                                    const baseY = textCombined.height / 2
                                    const difference = boundingBox.y - textCombined.yMin
                                    textBoundingBox[`#TEXT${i}`] = {
                                        x: preview.xShift + Math.floor(allRect.width + 2) / 2 - boundingBox.width / 2,
                                        y: preview.yShift + Math.floor(allRect.height + 2) / 2 - baseY + difference,
                                        width: boundingBox.width,
                                        height: boundingBox.height,
                                    }
                                })
                                console.log('result', textBoundingBox)
                            }
                        })
                    } else if (preview.type === 2) {
                        // Calculate the rectangle that surrounds both texts.
                        const textCombined = { yMin: 100000, yMax: 0, height: 1 }

                        node.childNodes.forEach(node => {
                            if (anim.textComps.includes(`#${node.id}`)) {
                                // The bounding box for each text.
                                const boundingBox = node.getBoundingClientRect()
                                // Get the minimum y of all texts. This is the y position at the top of the text.
                                textCombined.yMin = Math.min(textCombined.yMin, boundingBox.y)
                                // Get the maximum y of all texts. This is the y position at the bottom of the text.
                                textCombined.yMax = Math.max(textCombined.yMax, boundingBox.y + boundingBox.height)
                            }
                        })

                        // Calculate the combined height of all texts.
                        textCombined.height = textCombined.yMax - textCombined.yMin

                        node.childNodes.forEach(node => {
                            if (!anim.textComps.includes(`#${node.id}`)) {
                                node.childNodes.forEach((node, i) => {
                                    // Depending on the title count get the last elements.
                                    if (i >= node.childNodes.length - preview.elementCount) {
                                        const boundingBox = node.getBoundingClientRect()
                                        const baseY = textCombined.height / 2
                                        const difference = boundingBox.y - textCombined.yMin
                                        textBoundingBox[`#TEXT${i}`] = {
                                            x: preview.xShift + Math.floor(allRect.width + 2) / 2 - boundingBox.width / 2,
                                            y: preview.yShift + Math.floor(allRect.height + 2) / 2 - baseY + difference,
                                            width: boundingBox.width,
                                            height: boundingBox.height,
                                        }
                                    }
                                })
                            }
                        })
                    }
                }
                break
            }
        })

        tempsvg.removeChild(svgElement)
    }

    return {
        svgElement,
        allRect,
        previewData,
        textBoundingBox
    }
}

function Release() {
    const anim = this

    if (!anim) return
    if (!anim.isDOMLoaded) return

    const containerRef = document.getElementById(anim.id)
    try {
        anim.destroy()
    }
    catch (e) { console.log(e) }

    document.body.removeChild(containerRef)
}

window.LottieHelper = {
    LoadAnimation
}
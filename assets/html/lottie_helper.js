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

const SetTextTr = animationData => {
    const { assets } = animationData
    assets.forEach(item => {
        if (typeof item.nm === 'string' && item.nm.toLowerCase().startsWith('#text')) {
            item.layers.forEach(layer => {
                if (typeof layer.nm === 'string') {
                    let isTextLayer = false
                    if (layer.nm.toLowerCase().startsWith('@source')) isTextLayer = true
                    else if (layer.t && layer.t.d && typeof layer.t.d.x === 'string' && layer.t.d.x.includes('text.sourceText')) isTextLayer = true

                    if (isTextLayer) {
                        if (layer.t && layer.t.d && layer.t.d.k && layer.t.d.k[0] && layer.t.d.k[0].s) {
                            layer.t.d.k[0].s.tr = 75
                        }
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

    SetTextTr(animationData)

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
    anim.TextUpdate = TextUpdate
    anim.CopySVGElement = CopySVGElement
    anim.Release = Release
    anim.opentype = {}

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

        for (let i = 0; i < layers.length; i++) {
            const { nm, ip } = layers[i]
            if (nm.toLowerCase() === '@preview') {
                anim.previewFrame = ip
                anim.goToAndStop(ip, true)
            }
            anim.renderer.svgElement.childNodes.forEach(node => {
                if (node.tagName === 'g') {
                    RemoveMasks(node, false)
                }
            })
        }
    })

    return anim
}

const GetTextSourceLayers = (anim, compositionId) => {
    compositionId = compositionId.toLowerCase()

    const textSourceLayerElements = []

    for (let i = 0; i < anim.renderer.elements.length; i++) {
        const { data: { nm }, elements } = anim.renderer.elements[i]
        if (typeof nm === 'string' && nm.toLowerCase() === compositionId) {
            for (let j = 0; j < elements.length; j++) {
                const { data: { nm: sourceNm } } = elements[j]
                if (typeof sourceNm === 'string'
                    && sourceNm.toLowerCase() === '@source'
                    && typeof elements[j].updateDocumentData === 'function') {
                    textSourceLayerElements.push(elements[j])
                }
            }
        }
    }

    return textSourceLayerElements
}

function TextUpdate(compositionId, text, styles) {
    const anim = this

    if (!anim) return
    if (!anim.isDOMLoaded) return

    const textSourceLayerElements = GetTextSourceLayers(anim, compositionId)
    textSourceLayerElements.forEach(element => {
        element.updateDocumentData({ t: text })

        if (styles) {
            const { scale, fontFamily } = styles

            // TO DO : 레이어별 기본 폰트 사이즈 별도 저장 후 값 업데이트
            // element.setAttribute('origin-font-size', value)
        }
    })

    const previewFrame = anim.previewFrame || 0
    anim.goToAndStop(previewFrame + 1, true)
    anim.goToAndStop(previewFrame, true)
}

function CopySVGElement(frameNumber, opentypeMap) {
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
                svgElement.appendChild(defsEl)
            }
                break

            case 'g': {
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

        tempsvg.removeChild(svgElement)
    }

    return {
        svgElement,
        allRect,
        previewData
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
const { opentype } = window

const base64ToArrayBuffer = base64 => {
    var binary_string = atob(base64)
    var len = binary_string.length
    var bytes = new Uint8Array(len)
    for (var i = 0; i < len; i++) {
        bytes[i] = binary_string.charCodeAt(i)
    }
    return bytes.buffer
}

const LoadFontFamily = async (familyName, base64) => {
    const sleep = ms => new Promise(resolve => setTimeout(resolve, ms))
    try {
        const tagId = `font-${familyName}`
        if (!document.getElementById(tagId)) {
            const styleEl = document.createElement('style')
            styleEl.innerHTML = `
                @font-face {
                    font-family: ${familyName};
                    src: url(data:application/font-woff;charset=utf-8;base64,${base64});
                }
            `
            styleEl.id = tagId
            document.head.appendChild(styleEl)

            const div = document.createElement('div')
            div.className = `font-family-load-tag-${familyName}`
            div.style.position = 'absolute'
            div.style.left = '-99999px'
            div.style.fontFamily = familyName
            div.style.visibility = 'hidden'
            div.innerText = familyName
            document.body.appendChild(div)
        }

        // 최대 10초동안 로드
        for (let i = 0; i < 100; i++) {
            console.log(familyName, document.fonts.check(`12px ${familyName}`))
            if (document.fonts.check(`12px ${familyName}`)) return true

            await sleep(100)
        }
    }
    catch (e) {
        console.lop(e)
        console.log(err.stack)
    }
    return false
}

const LoadOpenTypeFromBase64 = base64 => opentype.parse(base64ToArrayBuffer(base64))

window.FontHelper = {
    LoadFontFamily,
    LoadOpenTypeFromBase64
}
const DrawPNG = (svgElement, x, y, width, height, allRect, previewData) => {
    return new Promise((resolve, reject) => {
        const image = new Image()
        const src = 'data:image/svg+xml,' + encodeURIComponent((new XMLSerializer).serializeToString(svgElement))
        image.onload = function (e) {
            const canvas = document.createElement('canvas')
            const ctx = canvas.getContext('2d')
            canvas.width = width
            canvas.height = height

            ctx.drawImage(image, x, y, width, height, 0, 0, width, height)

            if (allRect && previewData) {
                previewData.data.forEach((item, index) => {
                    const rectX = (previewData.data[index].rect.x - allRect.x) - 10
                    const rectY = (previewData.data[index].rect.y - allRect.y) - 10
                    const rectWidth = previewData.data[index].rect.width + 20
                    const rectHeight = previewData.data[index].rect.height + 20
                    ctx.globalAlpha = 0.2
                    ctx.fillRect(rectX, rectY, rectWidth, rectHeight)
                })
            }

            const base64 = canvas.toDataURL('image/png')

            document.body.appendChild(canvas)
            document.body.removeChild(canvas)
            
            resolve(base64)
        }
        image.onerror = function (e) {
            reject(e)
        }
        image.src = src
    })
}

window.CanvasHelper = {
    DrawPNG
}
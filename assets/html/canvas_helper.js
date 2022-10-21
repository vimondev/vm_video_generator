const DrawPNG = (svgElement, x, y, width, height) => {
    return new Promise((resolve, reject) => {
        const image = new Image()
        const src = 'data:image/svg+xml,' + encodeURIComponent((new XMLSerializer).serializeToString(svgElement))
        image.onload = function (e) {
            const canvas = document.createElement('canvas')
            const ctx = canvas.getContext('2d')
            canvas.width = width
            canvas.height = height

            ctx.drawImage(image, x, y, width, height, 0, 0, width, height)
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
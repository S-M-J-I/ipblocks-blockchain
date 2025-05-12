require("dotenv").config()

const express = require("express")
const { PinataSDK } = require("pinata")
const fs = require("fs")
const { Blob } = require("buffer")
const multer = require('multer')
const path = require('path')

const app = express()

const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        const uploadDir = path.join(__dirname, 'uploads');
        if (!fs.existsSync(uploadDir)) {
            fs.mkdirSync(uploadDir, { recursive: true });
        }
        cb(null, uploadDir);
    },
    filename: (req, file, cb) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        const extension = path.extname(file.originalname);
        cb(null, file.fieldname + '-' + uniqueSuffix + extension);
    }
})

const fileFilter = (req, file, cb) => {
    const allowedExtensions = ['.pdf', '.docx'];
    const fileExtension = path.extname(file.originalname).toLowerCase();

    if (allowedExtensions.includes(fileExtension)) {
        cb(null, true);
    } else {
        const error = new Error('Only PDF and DOCX files are allowed');
        error.code = 'INVALID_FILE_TYPE';
        cb(error, false);
    }
}


const upload = multer({
    storage: storage,
    fileFilter: fileFilter,
    limits: {
        fileSize: 500 * 1024 * 1024, // 500MB limit
        files: 10
    }
})


const pinata = new PinataSDK({
    pinataJwt: process.env.PINATA_JWT,
    pinataGateway: process.env.GATEWAY_URL
})

app.use(express.json())

app.post('/upload', upload.single('document'), async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({
                error: true,
                message: 'No file uploaded'
            })
        }

        const filePath = req.file.path
        const fileName = req.file.originalname
        const fileMimeType = req.file.mimetype

        const blob = new Blob([fs.readFileSync(filePath)])
        const file = new File([blob], fileName, { type: fileMimeType })
        const upload = await pinata.upload.public.file(file)

        fs.unlinkSync(filePath)

        res.status(200).json(upload)
    } catch (error) {
        console.log(error)
        res.status(500).json({
            error: true,
            message: 'Error uploading file',
            details: error.message
        });
    }
})


app.get('/get/:cid', async (req, res) => {
    try {
        const cid = req.params.cid

        const url = await pinata.gateways.private.createAccessLink({
            cid: cid,
            expires: 300, // valid for 5 mins
        });
        console.log(url)
        if (!url) {
            return res.status(404).json({
                error: true,
                message: 'No file found with this cid'
            })
        }

        res.status(200).send({
            url: url
        })
    } catch (error) {
        console.log(error)
        res.status(500).json({
            error: true,
            message: 'Error uploading file',
            details: error.message
        });
    }
})

const PORT = process.env.PORT || 3000
const HOST = process.env.HOST || "localhost"

app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
    console.log(`Upload IPFS endpoint: http://${HOST}:${PORT}/upload/single`)
})
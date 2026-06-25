import {Socket} from "phoenix"

const userTokenMeta = document.querySelector("meta[name='user-token']")
const userToken = userTokenMeta ? userTokenMeta.getAttribute("content") : null

let socket = new Socket("/socket", {params: {token: userToken}})
socket.connect()

export default socket

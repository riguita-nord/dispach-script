/* ======================================================
   REMOVER FUNDO PRETO DA NUI (SEGURO)
====================================================== */
window.addEventListener("DOMContentLoaded", () => {
    document.documentElement.style.background = "transparent";
    document.body.style.background = "transparent";
});


/* ======================================================
   HANDLER DO DISPATCH (POPUP + SOM + TECLA)
====================================================== */
window.addEventListener("message", (event) => {
    const data = event.data;
    if (!data || !data.action) return;


    /* -----------------------------------------
       1. SOM DO DISPATCH
    ----------------------------------------- */
    if (data.action === "playSound") {
        const audio = document.getElementById("dispatchSound");
        if (!audio) return;

        try {
            audio.pause();
            audio.currentTime = 0;

            audio.src = `./sounds/${data.sound || "noti_police_1"}.ogg`;
            audio.volume = data.volume || 0.75;

            audio.play().catch(() => {});
        } catch (err) {
            console.log("[DISPATCH] Erro no som:", err);
        }
    }


    /* -----------------------------------------
       2. POPUP DO DISPATCH (SEM BOTÃO)
    ----------------------------------------- */
    if (data.action === "openDispatch") {

        const box = document.getElementById("dispatchBox");
        if (!box) return;

        // textos
        document.getElementById("dispatchIcon").innerText  = data.icon  || "🚨";
        document.getElementById("dispatchTitle").innerText = data.title || "Alerta";
        document.getElementById("dispatchDesc").innerText  = data.desc  || "Localização Desconhecida";

        // tecla configurada no config
        const keyElem = document.getElementById("dispatchKey");
        if (keyElem) keyElem.innerText = data.key || "E";

        // **REMOVIDO**: botão dispatchAccept → SE NÃO EXISTE, NÃO ALTERA NADA
        // Não faz nada porque o botão foi removido do HTML.


        /* -------- MOSTRAR POPUP -------- */
        box.style.display = "flex";

        requestAnimationFrame(() => {
            box.classList.remove("animate");
            void box.offsetWidth;
            box.classList.add("animate");
        });


        /* -------- TIMEOUT -------- */
        clearTimeout(box._timer);
        box._timer = setTimeout(() => {

            box.classList.remove("animate");
            box.style.display = "none";

            // Informar o client.lua que popup fechou
            fetch(`https://${GetParentResourceName()}/popupClose`, {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({})
            });

        }, data.timeout || 5500);
    }
});

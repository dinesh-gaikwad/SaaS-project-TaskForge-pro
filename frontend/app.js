/* =========================================================
   AI StudySync 2027
   frontend/app.js
   Single Render Service Compatible
   ========================================================= */

/* ---------------------------------------------------------
   1. API CONFIGURATION
   --------------------------------------------------------- */

// Local + Render दोनों के लिए
const API = "";

// अगर अलग backend चलाना हो तो:
// const API = "http://127.0.0.1:8000";


/* ---------------------------------------------------------
   2. GLOBAL HELPERS
   --------------------------------------------------------- */

function $(id) {
    return document.getElementById(id);
}

function scrollToId(id) {
    const element = $(id);

    if (element) {
        element.scrollIntoView({
            behavior: "smooth",
            block: "start"
        });
    }
}

function showError(message) {
    console.error(message);
}


/* ---------------------------------------------------------
   3. API REQUEST HELPER
   --------------------------------------------------------- */

async function api(path, options = {}) {

    try {

        const response = await fetch(API + path, {
            ...options,
            headers: {
                "Content-Type": "application/json",
                ...(options.headers || {})
            }
        });

        if (!response.ok) {
            throw new Error(
                `API Error ${response.status}: ${response.statusText}`
            );
        }

        return await response.json();

    } catch (error) {

        console.error("API Request Failed:", error);

        throw error;
    }
}


/* ---------------------------------------------------------
   4. DASHBOARD
   --------------------------------------------------------- */

async function loadDashboard() {

    try {

        const stats = await api("/api/dashboard");

        if ($("groupsStat")) {
            $("groupsStat").textContent = stats.groups ?? 0;
        }

        if ($("resourcesStat")) {
            $("resourcesStat").textContent = stats.resources ?? 0;
        }

        if ($("quizStat")) {
            $("quizStat").textContent = stats.quizzes ?? 0;
        }

        if ($("tutorStat")) {
            $("tutorStat").textContent = stats.tutors ?? 0;
        }

    } catch (error) {

        showError("Dashboard loading failed");
    }
}


/* ---------------------------------------------------------
   5. STUDY GROUPS
   --------------------------------------------------------- */

async function loadGroups() {

    try {

        const data = await api("/api/groups");

        const container = $("groupGrid");

        if (!container) return;

        if (!data.length) {

            container.innerHTML = `
                <div class="card">
                    <h3>No Study Groups</h3>
                    <p class="muted">
                        Create your first study group.
                    </p>
                </div>
            `;

            return;
        }

        container.innerHTML = data.map(group => {

            return `
                <div class="card group-card">

                    <span class="eyebrow">
                        ${escapeHTML(group.topic)}
                    </span>

                    <h3>
                        ${escapeHTML(group.name)}
                    </h3>

                    <p class="muted">
                        ${group.members} learners
                        · shared resources
                        · live room
                    </p>

                    <div class="card-actions">

                        <button
                            class="ghost"
                            onclick="joinStudyRoom('${group.id}')">
                            Join Room
                        </button>

                        <button
                            class="primary"
                            onclick="viewGroup('${group.id}')">
                            View Group
                        </button>

                    </div>

                </div>
            `;

        }).join("");

    } catch (error) {

        const container = $("groupGrid");

        if (container) {

            container.innerHTML = `
                <div class="card">
                    <h3>Unable to load groups</h3>
                    <p class="muted">
                        Please check your server.
                    </p>
                </div>
            `;
        }
    }
}


/* ---------------------------------------------------------
   6. CREATE STUDY GROUP
   --------------------------------------------------------- */

async function createDemoGroup() {

    try {

        const group = await api(
            "/api/groups",
            {
                method: "POST",

                body: JSON.stringify({
                    name: "Full Stack AI Squad",
                    topic: "Software Engineering"
                })
            }
        );

        alert(
            `Study group "${group.name}" created successfully!`
        );

        await loadGroups();
        await loadDashboard();

    } catch (error) {

        alert("Unable to create study group.");
    }
}


/* ---------------------------------------------------------
   7. JOIN STUDY ROOM
   --------------------------------------------------------- */

function joinStudyRoom(groupId) {

    console.log("Joining study room:", groupId);

    scrollToId("rooms");

    const roomTitle = $("roomTitle");

    if (roomTitle) {

        roomTitle.textContent =
            `Live Study Room #${groupId}`;
    }
}


/* ---------------------------------------------------------
   8. VIEW GROUP
   --------------------------------------------------------- */

function viewGroup(groupId) {

    console.log("Opening group:", groupId);

    scrollToId("groups");

    alert(
        `Study Group ID: ${groupId}`
    );
}


/* ---------------------------------------------------------
   9. LOAD TUTORS
   --------------------------------------------------------- */

async function loadTutors() {

    try {

        const data = await api("/api/tutors");

        const container = $("tutorGrid");

        if (!container) return;

        if (!data.length) {

            container.innerHTML = `
                <div class="card">
                    <h3>No tutors available</h3>
                </div>
            `;

            return;
        }

        container.innerHTML = data.map(tutor => {

            return `
                <div class="card tutor-card">

                    <div class="tutor-avatar">
                        ${getInitials(tutor.name)}
                    </div>

                    <h3>
                        ${escapeHTML(tutor.name)}
                    </h3>

                    <p class="muted">
                        ${escapeHTML(tutor.skill)}
                    </p>

                    <strong>
                        $${tutor.rate}/hr
                    </strong>

                    <br><br>

                    <button
                        class="primary"
                        onclick="bookTutor('${tutor.id}')">
                        Book Session
                    </button>

                </div>
            `;

        }).join("");

    } catch (error) {

        console.error("Tutor loading failed:", error);
    }
}


/* ---------------------------------------------------------
   10. BOOK TUTOR
   --------------------------------------------------------- */

function bookTutor(tutorId) {

    alert(
        `Tutor booking started.\nTutor ID: ${tutorId}`
    );

    console.log(
        "Booking tutor:",
        tutorId
    );
}


/* ---------------------------------------------------------
   11. CHAT
   --------------------------------------------------------- */

async function loadChat() {

    try {

        const data = await api("/api/chat");

        const container = $("messages");

        if (!container) return;

        container.innerHTML = data.map(message => {

            return `
                <p>
                    <b>
                        ${escapeHTML(message.user)}:
                    </b>

                    ${escapeHTML(message.message)}
                </p>
            `;

        }).join("");

        container.scrollTop =
            container.scrollHeight;

    } catch (error) {

        console.error(
            "Chat loading failed:",
            error
        );
    }
}


/* ---------------------------------------------------------
   12. SEND CHAT MESSAGE
   --------------------------------------------------------- */

async function sendChat() {

    const input = $("chatInput");

    if (!input) return;

    const message =
        input.value.trim();

    if (!message) return;

    try {

        const response = await api(
            "/api/chat",
            {
                method: "POST",

                body: JSON.stringify({
                    user: "You",
                    message: message
                })
            }
        );

        const container =
            $("messages");

        if (container) {

            container.innerHTML += `
                <p>
                    <b>
                        ${escapeHTML(response.user)}:
                    </b>

                    ${escapeHTML(response.message)}
                </p>
            `;

            container.scrollTop =
                container.scrollHeight;
        }

        input.value = "";

    } catch (error) {

        alert(
            "Message could not be sent."
        );
    }
}


/* ---------------------------------------------------------
   13. ENTER KEY CHAT
   --------------------------------------------------------- */

function setupChatKeyboard() {

    const input = $("chatInput");

    if (!input) return;

    input.addEventListener(
        "keydown",
        function(event) {

            if (event.key === "Enter") {

                event.preventDefault();

                sendChat();
            }
        }
    );
}


/* ---------------------------------------------------------
   14. WHITEBOARD
   --------------------------------------------------------- */

let canvas = null;
let ctx = null;

let drawing = false;
let lastPoint = null;

function setupWhiteboard() {

    canvas = $("canvas");

    if (!canvas) {

        console.warn(
            "Whiteboard canvas not found."
        );

        return;
    }

    ctx =
        canvas.getContext("2d");

    ctx.lineCap = "round";
    ctx.lineJoin = "round";

    canvas.addEventListener(
        "pointerdown",
        startDrawing
    );

    canvas.addEventListener(
        "pointermove",
        draw
    );

    canvas.addEventListener(
        "pointerup",
        stopDrawing
    );

    canvas.addEventListener(
        "pointerleave",
        stopDrawing
    );
}


/* ---------------------------------------------------------
   15. START DRAWING
   --------------------------------------------------------- */

function startDrawing(event) {

    if (!canvas || !ctx) return;

    drawing = true;

    lastPoint =
        getCanvasPosition(event);

    canvas.setPointerCapture(
        event.pointerId
    );
}


/* ---------------------------------------------------------
   16. DRAW
   --------------------------------------------------------- */

function draw(event) {

    if (
        !drawing ||
        !canvas ||
        !ctx ||
        !lastPoint
    ) {
        return;
    }

    const currentPoint =
        getCanvasPosition(event);

    ctx.beginPath();

    ctx.moveTo(
        lastPoint.x,
        lastPoint.y
    );

    ctx.lineTo(
        currentPoint.x,
        currentPoint.y
    );

    ctx.strokeStyle =
        "#55e6a5";

    ctx.lineWidth = 3;

    ctx.stroke();

    lastPoint =
        currentPoint;
}


/* ---------------------------------------------------------
   17. STOP DRAWING
   --------------------------------------------------------- */

function stopDrawing(event) {

    drawing = false;

    lastPoint = null;

    if (
        canvas &&
        event &&
        canvas.hasPointerCapture &&
        canvas.hasPointerCapture(
            event.pointerId
        )
    ) {

        canvas.releasePointerCapture(
            event.pointerId
        );
    }
}


/* ---------------------------------------------------------
   18. CANVAS POSITION
   --------------------------------------------------------- */

function getCanvasPosition(event) {

    const rect =
        canvas.getBoundingClientRect();

    return {

        x:
            (event.clientX - rect.left)
            *
            canvas.width
            /
            rect.width,

        y:
            (event.clientY - rect.top)
            *
            canvas.height
            /
            rect.height
    };
}


/* ---------------------------------------------------------
   19. CLEAR WHITEBOARD
   --------------------------------------------------------- */

function clearWhiteboard() {

    if (!canvas || !ctx) return;

    ctx.clearRect(
        0,
        0,
        canvas.width,
        canvas.height
    );
}


/* ---------------------------------------------------------
   20. RESOURCE LOADING
   --------------------------------------------------------- */

async function loadResources() {

    try {

        const data =
            await api("/api/resources");

        const container =
            $("resourceGrid");

        if (!container) return;

        container.innerHTML =
            data.map(resource => {

                return `
                    <div class="card">

                        <span class="eyebrow">
                            ${escapeHTML(resource.type)}
                        </span>

                        <h3>
                            ${escapeHTML(resource.title)}
                        </h3>

                        <button
                            class="ghost"
                            onclick="openResource('${resource.id}')">
                            Open Resource
                        </button>

                    </div>
                `;

            }).join("");

    } catch (error) {

        console.error(
            "Resource loading failed:",
            error
        );
    }
}


/* ---------------------------------------------------------
   21. OPEN RESOURCE
   --------------------------------------------------------- */

function openResource(resourceId) {

    alert(
        `Resource ID: ${resourceId}`
    );
}


/* ---------------------------------------------------------
   22. QUIZZES
   --------------------------------------------------------- */

async function loadQuizzes() {

    try {

        const data =
            await api("/api/quizzes");

        const container =
            $("quizGrid");

        if (!container) return;

        container.innerHTML =
            data.map(quiz => {

                return `
                    <div class="card">

                        <span class="eyebrow">
                            QUIZ
                        </span>

                        <h3>
                            ${escapeHTML(quiz.title)}
                        </h3>

                        <p class="muted">
                            ${quiz.questions}
                            questions
                        </p>

                        <p>
                            Best Score:
                            <strong>
                                ${quiz.best_score}%
                            </strong>
                        </p>

                        <button
                            class="primary"
                            onclick="startQuiz('${quiz.id}')">
                            Start Quiz
                        </button>

                    </div>
                `;

            }).join("");

    } catch (error) {

        console.error(
            "Quiz loading failed:",
            error
        );
    }
}


/* ---------------------------------------------------------
   23. START QUIZ
   --------------------------------------------------------- */

function startQuiz(quizId) {

    alert(
        `Quiz ${quizId} started!`
    );
}


/* ---------------------------------------------------------
   24. INITIALIZE APPLICATION
   --------------------------------------------------------- */

async function initializeApp() {

    console.log(
        "StudySync application starting..."
    );

    await loadDashboard();

    await loadGroups();

    await loadTutors();

    await loadChat();

    await loadResources();

    await loadQuizzes();

    setupChatKeyboard();

    setupWhiteboard();

    console.log(
        "StudySync application ready."
    );
}


/* ---------------------------------------------------------
   25. HTML ESCAPE
   --------------------------------------------------------- */

function escapeHTML(value) {

    if (value === null ||
        value === undefined) {

        return "";
    }

    return String(value)
        .replaceAll("&", "&amp;")
        .replaceAll("<", "&lt;")
        .replaceAll(">", "&gt;")
        .replaceAll('"', "&quot;")
        .replaceAll("'", "&#039;");
}


/* ---------------------------------------------------------
   26. INITIALS
   --------------------------------------------------------- */

function getInitials(name) {

    if (!name) return "?";

    return name
        .split(" ")
        .map(word => word[0])
        .join("")
        .substring(0, 2)
        .toUpperCase();
}


/* ---------------------------------------------------------
   27. START
   --------------------------------------------------------- */

document.addEventListener(
    "DOMContentLoaded",
    initializeApp
);
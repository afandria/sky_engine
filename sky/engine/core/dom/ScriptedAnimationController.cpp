/*
 * Copyright (C) 2011 Google Inc. All Rights Reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 *  THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS'' AND ANY
 *  EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 *  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 *  DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 *  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 *  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 *  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 *  ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 *  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

#include "sky/engine/core/dom/ScriptedAnimationController.h"

#include "sky/engine/core/css/MediaQueryListListener.h"
#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/RequestAnimationFrameCallback.h"
#include "sky/engine/core/events/Event.h"
#include "sky/engine/core/frame/FrameView.h"
#include "sky/engine/core/frame/LocalDOMWindow.h"
#include "sky/engine/core/page/Page.h"
#include "sky/engine/platform/Logging.h"

namespace blink {

ScriptedAnimationController::ScriptedAnimationController(Document* document)
    : m_document(document)
    , m_nextCallbackId(0)
    , m_suspendCount(0)
{
}

ScriptedAnimationController::~ScriptedAnimationController()
{
}

void ScriptedAnimationController::suspend()
{
    ++m_suspendCount;
    WTF_LOG(ScriptedAnimationController, "suspend: count = %d", m_suspendCount);
}

void ScriptedAnimationController::resume()
{
    // It would be nice to put an ASSERT(m_suspendCount > 0) here, but in WK1 resume() can be called
    // even when suspend hasn't (if a tab was created in the background).
    if (m_suspendCount > 0)
        --m_suspendCount;
    WTF_LOG(ScriptedAnimationController, "resume: count = %d", m_suspendCount);
    scheduleAnimationIfNeeded();
}

ScriptedAnimationController::CallbackId ScriptedAnimationController::registerCallback(PassOwnPtr<RequestAnimationFrameCallback> callback)
{
    ScriptedAnimationController::CallbackId id = ++m_nextCallbackId;
    WTF_LOG(ScriptedAnimationController, "registerCallback: id = %d", id);
    callback->m_cancelled = false;
    callback->m_id = id;
    m_callbacks.append(callback);
    scheduleAnimationIfNeeded();
    return id;
}

void ScriptedAnimationController::cancelCallback(CallbackId id)
{
    WTF_LOG(ScriptedAnimationController, "cancelCallback: id = %d", id);
    for (size_t i = 0; i < m_callbacks.size(); ++i) {
        if (m_callbacks[i]->m_id == id) {
            m_callbacks.remove(i);
            return;
        }
    }
    for (size_t i = 0; i < m_callbacksToInvoke.size(); ++i) {
        if (m_callbacksToInvoke[i]->m_id == id) {
            m_callbacksToInvoke[i]->m_cancelled = true;
            // will be removed at the end of executeCallbacks()
            return;
        }
    }
}

void ScriptedAnimationController::dispatchEvents()
{
    Vector<RefPtr<Event> > events;
    events.swap(m_eventQueue);
}

void ScriptedAnimationController::executeCallbacks(double monotonicTimeNow)
{
    // dispatchEvents() runs script which can cause the document to be destroyed.
    if (!m_document)
        return;

    double highResNowMs = 1000.0 * monotonicTimeNow;

    // First, generate a list of callbacks to consider.  Callbacks registered from this point
    // on are considered only for the "next" frame, not this one.
    ASSERT(m_callbacksToInvoke.isEmpty());
    m_callbacksToInvoke.swap(m_callbacks);

    for (size_t i = 0; i < m_callbacksToInvoke.size(); ++i) {
        RequestAnimationFrameCallback* callback = m_callbacksToInvoke[i].get();
        if (!callback->m_cancelled)
            callback->handleEvent(highResNowMs);
    }

    m_callbacksToInvoke.clear();
}

void ScriptedAnimationController::callMediaQueryListListeners()
{
    MediaQueryListListeners listeners;
    listeners.swap(m_mediaQueryListListeners);

    for (MediaQueryListListeners::const_iterator it = listeners.begin(), end = listeners.end();
        it != end; ++it) {
        (*it)->notifyMediaQueryChanged();
    }
}

void ScriptedAnimationController::serviceScriptedAnimations(double monotonicTimeNow)
{
    WTF_LOG(ScriptedAnimationController, "serviceScriptedAnimations: #callbacks = %d, #events = %d, #mediaQueryListListeners = %d, count = %d",
        static_cast<int>(m_callbacks.size()),
        static_cast<int>(m_eventQueue.size()),
        static_cast<int>(m_mediaQueryListListeners.size()),
        m_suspendCount);
    if (!m_callbacks.size() && !m_eventQueue.size() && !m_mediaQueryListListeners.size())
        return;

    if (m_suspendCount)
        return;

    RefPtr<ScriptedAnimationController> protect(this);

    callMediaQueryListListeners();
    dispatchEvents();
    executeCallbacks(monotonicTimeNow);

    scheduleAnimationIfNeeded();
}

void ScriptedAnimationController::enqueueEvent(PassRefPtr<Event> event)
{
    WTF_LOG(ScriptedAnimationController, "enqueueEvent");
    m_eventQueue.append(event);
    scheduleAnimationIfNeeded();
}

void ScriptedAnimationController::enqueuePerFrameEvent(PassRefPtr<Event> event)
{
    enqueueEvent(event);
}

void ScriptedAnimationController::enqueueMediaQueryChangeListeners(Vector<RefPtr<MediaQueryListListener> >& listeners)
{
    WTF_LOG(ScriptedAnimationController, "enqueueMediaQueryChangeListeners");
    for (size_t i = 0; i < listeners.size(); ++i) {
        m_mediaQueryListListeners.add(listeners[i]);
    }
    scheduleAnimationIfNeeded();
}

void ScriptedAnimationController::scheduleAnimationIfNeeded()
{
    WTF_LOG(ScriptedAnimationController, "scheduleAnimationIfNeeded: document = %d, count = %d, #callbacks = %d, #events = %d, #mediaQueryListListeners =%d, frameView = %d",
        m_document ? 1 : 0, m_suspendCount,
        static_cast<int>(m_callbacks.size()),
        static_cast<int>(m_eventQueue.size()),
        static_cast<int>(m_mediaQueryListListeners.size()),
        m_document && m_document->view() ? 1 : 0);
    if (!m_document)
        return;

    if (m_suspendCount)
        return;

    if (!m_callbacks.size() && !m_eventQueue.size() && !m_mediaQueryListListeners.size())
        return;

    // TODO(esprehn): This causes a full raster on every raf even if nothing changed.
    m_document->page()->scheduleVisualUpdate();
}

}

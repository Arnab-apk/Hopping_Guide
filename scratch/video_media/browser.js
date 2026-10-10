import { StreamVideoClient } from '@stream-io/video-client';
window.joinMedia = async session => {
  const client = new StreamVideoClient({ apiKey: session.apiKey, token: session.token,
    user: { id: session.userId }, options: { logLevel: 'error' } });
  const call = client.call(session.callType, session.callId);
  window.mediaClient = client; window.mediaCall = call;
  await call.join({ create: false });
  const parent = document.getElementById('participants');
  call.setViewport(parent);
  const bound = new Set();
  call.state.participants$.subscribe(participants => {
    window.mediaParticipantCount = participants.length;
    for (const participant of participants) {
      if (bound.has(participant.sessionId)) continue;
      bound.add(participant.sessionId);
      const video = document.createElement('video');
      video.width = 250; video.height = 180; video.autoplay = true; video.muted = true;
      parent.appendChild(video);
      call.trackElementVisibility(video, participant.sessionId, 'videoTrack');
      call.bindVideoElement(video, participant.sessionId, 'videoTrack');
      if (!participant.isLocalParticipant) {
        const audio = document.createElement('audio'); audio.autoplay = true;
        parent.appendChild(audio); call.bindAudioElement(audio, participant.sessionId);
      }
    }
  });
  await call.camera.enable(); await call.microphone.enable();
};
window.mediaStats = async () => {
  const stats = { participants: window.mediaParticipantCount || 0, videoFrames: 0, audioPackets: 0 };
  for (const connection of window.mediaConnections) {
    const reports = await connection.getStats();
    for (const report of reports.values()) {
      if (report.type !== 'inbound-rtp') continue;
      if (report.kind === 'video') stats.videoFrames += report.framesDecoded || 0;
      if (report.kind === 'audio') stats.audioPackets += report.packetsReceived || 0;
    }
  }
  return stats;
};

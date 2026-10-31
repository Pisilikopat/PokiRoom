import { createClient } from 'npm:@supabase/supabase-js@2'
import { JWT } from 'npm:google-auth-library@9'

interface WebhookPayload {
  type: string
  table: string
  schema: string
  record: any
  old_record: any
}

// Generate Google OAuth 2.0 access token using Firebase service account
async function getAccessToken(clientEmail: string, privateKey: string): Promise<string> {
  const jwtClient = new JWT({
    email: clientEmail,
    key: privateKey.replace(/\\n/g, '\n'),
    scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
  })
  const res = await jwtClient.getAccessToken()
  if (!res?.token) {
    throw new Error('Failed to retrieve access token from Google Auth')
  }
  return res.token
}

Deno.serve(async (req) => {
  try {
    const payload: WebhookPayload = await req.json()
    console.log(`[PokiRoom Push] Event on table '${payload.table}', type '${payload.type}'`)

    const serviceAccountJson = Deno.env.get('FIREBASE_SERVICE_ACCOUNT')
    if (!serviceAccountJson) {
      throw new Error('FIREBASE_SERVICE_ACCOUNT environment secret is missing!')
    }
    const serviceAccount = JSON.parse(serviceAccountJson)

    // Supabase admin client to query user & room data
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    let receiverId: string | null = null
    let title = ''
    let body = ''
    let route = '/'

    if (payload.table === 'room_notifications') {
      const rec = payload.record
      receiverId = rec.receiver_id
      title = rec.title || 'PokiRoom 🐾'
      body = rec.body || 'Yeni bir bildirim var!'
      route = rec.type === 'knock' ? '/empty-pocket' : '/room'
    } else if (payload.table === 'messages') {
      const rec = payload.record

      // Find partner in room
      const { data: room, error: roomErr } = await supabase
        .from('rooms')
        .select('user1_id, user2_id')
        .eq('id', rec.room_id)
        .single()

      if (roomErr || !room) {
        console.error('[PokiRoom Push] Room not found for message', roomErr)
        return new Response(JSON.stringify({ error: 'room_not_found' }), { status: 200 })
      }

      receiverId = room.user1_id === rec.sender_id ? room.user2_id : room.user1_id

      // Fetch sender nickname
      const { data: sender } = await supabase
        .from('users')
        .select('nickname')
        .eq('id', rec.sender_id)
        .single()

      const senderName = sender?.nickname || 'Partnerin'
      title = `🐾 ${senderName}`

      if (rec.message_type === 'text') {
        body = rec.content
      } else if (rec.message_type === 'sticker') {
        body = '🎨 Sana bir çıkartma gönderdi!'
      } else if (rec.message_type === 'foggy') {
        body = '✨ Gizemli bir buğulu mesaj gönderdi!'
      } else {
        body = 'Yeni bir mesaj gönderdi.'
      }
      route = '/room'
    } else {
      return new Response(JSON.stringify({ message: 'ignored_table' }), { status: 200 })
    }

    if (!receiverId) {
      return new Response(JSON.stringify({ message: 'no_receiver' }), { status: 200 })
    }

    // Fetch receiver's FCM token from users table
    const { data: user, error: userErr } = await supabase
      .from('users')
      .select('fcm_token')
      .eq('id', receiverId)
      .single()

    if (userErr || !user?.fcm_token) {
      console.log(`[PokiRoom Push] User ${receiverId} has no fcm_token registered, skipping push.`)
      return new Response(JSON.stringify({ skipped: 'no_fcm_token' }), { status: 200 })
    }

    const fcmToken = user.fcm_token
    console.log(`[PokiRoom Push] Dispatching push to ${receiverId} (token: ${fcmToken.substring(0, 16)}...)`)

    // Get OAuth2 token for Firebase Cloud Messaging
    const accessToken = await getAccessToken(serviceAccount.client_email, serviceAccount.private_key)

    // FCM HTTP v1 Message payload
    const fcmPayload = {
      message: {
        token: fcmToken,
        notification: {
          title: title,
          body: body,
        },
        android: {
          priority: 'HIGH',
          notification: {
            channel_id: 'poki_channel',
            sound: 'default',
            default_sound: true,
            default_vibrate_timings: true,
            notification_priority: 'PRIORITY_HIGH',
          },
        },
        data: {
          route: route,
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
      },
    }

    const res = await fetch(
      `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${accessToken}`,
        },
        body: JSON.stringify(fcmPayload),
      }
    )

    const resText = await res.text()
    if (!res.ok) {
      console.error(`[PokiRoom Push] FCM send failed: ${res.status} ${resText}`)
      return new Response(resText, { status: 500 })
    }

    console.log(`[PokiRoom Push] FCM successfully delivered: ${resText}`)
    return new Response(resText, {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (err: any) {
    console.error('[PokiRoom Push] Error:', err.message)
    return new Response(JSON.stringify({ error: err.message }), { status: 500 })
  }
})

import { Handler, Context, Callback } from 'aws-lambda'
import { BadRequest, Ok, Created } from './response';

export const ping: Handler = (event: any, context: Context, callback: Callback) => {
  callback(undefined, Ok())
}

export const pingPath: Handler = (event: any, context: Context, callback: Callback) => {
  try {
    const id = event.pathParameters.id

    if (id === null) {
      callback(undefined, BadRequest("id was not found in the request path"))
      return
    }

    callback(undefined, Ok({
      pathReceived: id
    }))
  } catch (error) {
    callback(error, BadRequest(error))
  }
}

export const pingPost: Handler = (event: any, context: Context, callback: Callback) => {
  try {
    const body = JSON.parse(event.body)
    const id = body.id

    if(!id) {
      callback(undefined, BadRequest("id not found in message body"))
      return
    }

    const response = {
        success: "true",
        message: `id: ${id}`
    }

    callback(undefined, Created(response))
} catch (error) {
    callback(error, {
        statusCode: 400,
        body: JSON.stringify({
            error: error
        })
    })
}
}

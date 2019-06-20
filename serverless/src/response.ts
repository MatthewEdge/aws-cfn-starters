export interface LambdaResponse {
  statusCode: number
  headers?: any
  body: string
}

export function Ok(...body: any): LambdaResponse {
  return {
    statusCode: 200,
    body: JSON.stringify(body)
  }
}

export function Created(body: any): LambdaResponse {
  return {
    statusCode: 201,
    body: JSON.stringify(body)
  }
}

export function Accepted(body: any): LambdaResponse {
  return {
    statusCode: 203,
    body: JSON.stringify(body)
  }
}

export function BadRequest(message: string): LambdaResponse {
  return {
    statusCode: 400,
    body: JSON.stringify({
      error: message
    })
  }
}

export function Unauthorized(): LambdaResponse {
  return {
    statusCode: 401,
    body: JSON.stringify({
      error: "Missing credentials in request"
    })
  }
}

export function Forbidden(): LambdaResponse {
  return {
    statusCode: 403,
    body: JSON.stringify({
      error: "You are not authorized to access this resource"
    })
  }
}

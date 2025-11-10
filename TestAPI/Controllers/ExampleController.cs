using System;
using Microsoft.AspNetCore.Mvc;
using Minio;
using Minio.DataModel.Args;

namespace TestAPI.Controllers;


[ApiController]
public class ExampleController : ControllerBase
{
    private readonly IMinioClient minioClient;

    public ExampleController(IMinioClient minioClient)
    {
        this.minioClient = minioClient;
    }

    [HttpGet]
    [ProducesResponseType(typeof(string), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetUrl(string bucketID)
    {
        return Ok(await minioClient.PresignedGetObjectAsync(new PresignedGetObjectArgs()
                .WithBucket(bucketID))
            .ConfigureAwait(false));
    }
}


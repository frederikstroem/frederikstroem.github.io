---
layout: post
is_post: true

title: AI-generated rabbit hole
#last_modified: YYYY-MM-DD
---
Over the weekend, I fell into a small [AI-generated art creation](https://en.wikipedia.org/wiki/Text-to-image_model) rabbit hole.

I started by joining the [Midjourney Discord](https://discord.gg/midjourney).<br>BTW, they have a pretty 🔥 [website](https://www.midjourney.com).

I started out with the prompt `monstertruck on a rainbow in space`, I think it turned out pretty cool! 😎

<img src="https://cdn.jsdelivr.net/gh/frederikstroem/AI-generated-art/Midjourney/Midjourney_monstertruck_on_a_rainbow_in_space.png" alt="monstertruck on a rainbow in space" />

Midjourney is cool and all, but it was nice getting a little more hands on. I spun up a [Stable Diffusion](https://github.com/CompVis/stable-diffusion) Jupyter notebook on my server equipped with and old but trusty Nvidia GeForce GTX 1070 Founders Edition, and started generating some images.

I got some interesting results with the prompt `cyberpunk`.

<div class="imgWrapper">
    <img src="https://cdn.jsdelivr.net/gh/frederikstroem/AI-generated-art/Stable-Diffusion/cyberpunk/2022_09_25_15_58_cyberpunk.png" alt="cyberpunk" />
    <img src="https://cdn.jsdelivr.net/gh/frederikstroem/AI-generated-art/Stable-Diffusion/cyberpunk/2022_09_25_16_48_cyberpunk.png" alt="cyberpunk" />
    <img src="https://cdn.jsdelivr.net/gh/frederikstroem/AI-generated-art/Stable-Diffusion/cyberpunk/2022_09_25_15_37_cyberpunk.png" alt="cyberpunk" />
    <img src="https://cdn.jsdelivr.net/gh/frederikstroem/AI-generated-art/Stable-Diffusion/cyberpunk/2022_09_25_15_56_cyberpunk.png" alt="cyberpunk" />
</div>

Seems the training set is a little biased towards Keanu Reeves. 🤣👌

<div class="imgWrapper">
    <img src="https://cdn.jsdelivr.net/gh/frederikstroem/AI-generated-art/Stable-Diffusion/cyberpunk/2022_09_25_16_00_cyberpunk.png" alt="cyberpunk" />
    <img src="https://cdn.jsdelivr.net/gh/frederikstroem/AI-generated-art/Stable-Diffusion/cyberpunk/2022_09_25_15_38_cyberpunk.png" alt="cyberpunk" />
</div>

My `mountain village, cyberpunk, snow, island, sunset` prompt also turned out pretty great!


<div class="imgWrapper">
    <img src="https://cdn.jsdelivr.net/gh/frederikstroem/AI-generated-art/Stable-Diffusion/mountain_village,_cyberpunk,_snow,_island,_sunset/2022_09_25_21_03_mountain_village,_cyberpunk,_snow,_island,_sunset.png" alt="mountain village, cyberpunk, snow, island, sunset" />
    <img src="https://cdn.jsdelivr.net/gh/frederikstroem/AI-generated-art/Stable-Diffusion/mountain_village,_cyberpunk,_snow,_island,_sunset/2022_09_25_21_00_mountain_village,_cyberpunk,_snow,_island,_sunset.png" alt="mountain village, cyberpunk, snow, island, sunset" />
    <img src="https://cdn.jsdelivr.net/gh/frederikstroem/AI-generated-art/Stable-Diffusion/mountain_village,_cyberpunk,_snow,_island,_sunset/2022_09_25_20_56_mountain_village,_cyberpunk,_snow,_island,_sunset.png" alt="mountain village, cyberpunk, snow, island, sunset" />
    <img src="https://cdn.jsdelivr.net/gh/frederikstroem/AI-generated-art/Stable-Diffusion/mountain_village,_cyberpunk,_snow,_island,_sunset/2022_09_25_20_52_mountain_village,_cyberpunk,_snow,_island,_sunset.png" alt="mountain village, cyberpunk, snow, island, sunset" />
    <img src="https://cdn.jsdelivr.net/gh/frederikstroem/AI-generated-art/Stable-Diffusion/mountain_village,_cyberpunk,_snow,_island,_sunset/2022_09_25_20_38_mountain_village,_cyberpunk,_snow,_island,_sunset.png" alt="mountain village, cyberpunk, snow, island, sunset" />
    <img src="https://cdn.jsdelivr.net/gh/frederikstroem/AI-generated-art/Stable-Diffusion/mountain_village,_cyberpunk,_snow,_island,_sunset/2022_09_25_20_42_mountain_village,_cyberpunk,_snow,_island,_sunset.png" alt="mountain village, cyberpunk, snow, island, sunset" />
    <img src="https://cdn.jsdelivr.net/gh/frederikstroem/AI-generated-art/Stable-Diffusion/mountain_village,_cyberpunk,_snow,_island,_sunset/2022_09_25_20_22_mountain_village,_cyberpunk,_snow,_island,_sunset.png" alt="mountain village, cyberpunk, snow, island, sunset" />
    <img src="https://cdn.jsdelivr.net/gh/frederikstroem/AI-generated-art/Stable-Diffusion/mountain_village,_cyberpunk,_snow,_island,_sunset/2022_09_25_20_26_mountain_village,_cyberpunk,_snow,_island,_sunset.png" alt="mountain village, cyberpunk, snow, island, sunset" />
</div>

Also, text is kinda weird xD

<div class="imgWrapper">
    <img src="https://cdn.jsdelivr.net/gh/frederikstroem/AI-generated-art/Stable-Diffusion/cyberpunk/2022_09_25_17_36_cyberpunk.png" alt="cyberpunk" />
    <img src="https://cdn.jsdelivr.net/gh/frederikstroem/AI-generated-art/Stable-Diffusion/cyberpunk/2022_09_25_17_34_cyberpunk.png" alt="cyberpunk" />
</div>

I ended up also renting a bit of compute at [Replicate](https://replicate.com) to make some animated Stable Diffusion prompts using [deforum_stable_diffusion](https://replicate.com/deforum/deforum_stable_diffusion). I really liked `monstertruck on a rainbow in space high quality cartoon style`

<video loop controls autoplay>
  <source src="https://cdn.jsdelivr.net/gh/frederikstroem/AI-generated-art/deforum_stable_diffusion/deforum_stable_diffusion_2022-09-23_monstertruck_on_a_rainbow_in_space_high_quality_cartoon_style.mp4" type="video/mp4">
  Your browser does not support the video tag.
</video>

That's it for now! 🎉

I documented some of the cooler creations in a [GitHub repository](https://github.com/frederikstroem/AI-generated-art).

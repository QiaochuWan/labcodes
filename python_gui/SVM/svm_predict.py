#!/usr/bin/env python
# coding: utf-8

# In[6]:


def svm_model(path):
    import joblib
    from scipy import io
    import numpy as np
    from scipy.io import savemat
    svm_model1 = joblib.load(path + 'svm_model.m')
    path2 = path + 'im2_con.mat'
    data2 = io.loadmat(path2)
    data2 = data2['im2_con']
    data2 = data2[0, :, :]
    PreResult = svm_model1.predict(data2)
    DrawResult = data2
    for i in range(len(DrawResult)):
        if PreResult[i] == 0:
            DrawResult[i, :] = [0, 0, 0] #Black for Background
        elif PreResult[i] == 1:
            DrawResult[i, :] = [0, 255, 0] #Green for Thin
        elif PreResult[i] == 2:
            DrawResult[i, :] = [0, 0, 255] #Blue for Bulk
        elif PreResult[i] == 3:
            DrawResult[i, :] = [255, 255, 0] #Yellow for Bulk
        elif PreResult[i] == 4:
            DrawResult[i, :] = [255, 0, 0] #Red for Bulk     
    DrawResult = np.array([DrawResult])
    savemat(path + "DrawResult.mat", {'DrawResult' : DrawResult})
    return


# In[ ]:




